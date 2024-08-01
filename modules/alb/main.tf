# Security Group for ALB
resource "aws_security_group" "sg_ecs_alb" {
  name        = "${local.name}-load-balancer"
  description = "allow HTTP to ${local.name} Load Balancer (ALB)"
  vpc_id      = var.vpc

  tags = {
    Name = local.name
    Team = "Glacier"
  }
}

# Create a single load balancer for all Ecs services
resource "aws_alb" "ecs_alb" {
  name                       = local.name
  internal                   = true
  idle_timeout               = "300"
  security_groups            = var.security_groups
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
resource "aws_alb_listener" "listen2" {
  load_balancer_arn = aws_alb.ecs_alb.arn
  port              = "443"
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
  name        = "${local.name}-ecs"
  port        = 443
  protocol    = "HTTPS"
  vpc_id      = var.vpc
  target_type = "instance"
}
