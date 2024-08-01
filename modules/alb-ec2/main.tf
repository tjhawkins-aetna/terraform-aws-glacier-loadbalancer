# Security Group for ALB
resource "aws_security_group" "sg_ec2_alb" {
  name        = "${local.name}-load-balancer"
  description = "allow HTTP to ${local.name} Load Balancer (ALB)"
  vpc_id      = var.vpc
  tags = {
    Name = local.name
    Team = "Glacier"
  }
}

resource "aws_security_group_rule" "sg_ec2_alb" {
  type              = "ingress"
  from_port         = var.port_number
  to_port           = var.port_number
  protocol          = "tcp"
  cidr_blocks       = [var.security_group_cidr_range]
  security_group_id = var.security_groups
}

resource "aws_security_group_rule" "sg_ec2_alb_1" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = var.security_groups
}


# Create a single load balancer
resource "aws_alb" "ec2_alb" {
  name                       = local.name
  internal                   = true
  idle_timeout               = "300"
  security_groups            = [var.security_groups]
  subnets                    = var.subnets
  enable_deletion_protection = false

  access_logs {
    bucket  = "aetna-digital-aws-${local.account_alias}-us-east-1-logs"
    enabled = true
  }

  tags = {
    Name = local.name
  }
}

# Define a listener
resource "aws_alb_listener" "listen" {
  load_balancer_arn = aws_alb.ec2_alb.arn
  port              = var.port_number
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "YOU HAVE REACHED DEFAULT SSL ACTION. HTTP STATUS CODE RESPONSE 200 \n"
      status_code  = "200"
    }
  }
}

# Connect TG up to the Application Load Balancer
resource "aws_alb_target_group" "destination" {
  name        = "${local.name}-ec2"
  port        = var.target_port_number
  protocol    = "HTTP"
  vpc_id      = var.vpc
  target_type = "instance"
}

resource "aws_alb_listener_rule" "ec2_example_service" {
  listener_arn = aws_alb_listener.listen.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.destination.arn
  }

  condition {
    host_header {
      values = ["${var.endpoint}.${var.environment}.aetnadigital.net"]
    }
  }
}

resource "aws_lb_target_group_attachment" "ec2" {
  target_group_arn = aws_alb_target_group.destination.arn
  target_id        = var.target_ec2
  port             = var.target_port_number
}
