# Overview
This document outlines the findings for integrating an Application Load Balancer routing to an ECS cluster

## Components
1. Application Load Balancer: This is a load balancer that is capable of routing based on a path or a host header.
2. Target Group: A target group is where ecs containers register. Actions taken by the load balancer forward to target groups. Target groups are also responsible for health checks of the destination tasks.
3. ECS: This is the host container orchestration platform where tasks run

## Terraform Elements
There are two independent functions built by terraform in this demo.
1. The Application Load Balancer (ALB) infrastructure defines the load balancer, the listening port(s), the target groups and the listening rules for routing.
2. The second function is the ECS components. This includes task definitions, container definitions, and service definitions.

## ALB
The ALB configuration has required fields. Most of these can be data sourced. With enable\_deletion\_protection set to true the alb cannot be accidentally deleted.

```
resource "aws_alb" "ecs-alb" {
  name            = "${var.name}"
  internal        = true
  idle_timeout    = "300"
  security_groups = ["${aws_security_group.sg-ecs-alb.id}", "sg-5344ed22", "sg-5144ed20"]
  subnets = ["subnet-5ee71004", "subnet-d05072b5"]
  enable_deletion_protection = false

  tags {
    Name = "${var.name}"
  }
}
```

## Listening Ports
Listening ports are the ports the ALB listens on for traffic. This would typically be 443 and/or 80. The default action results in the final routing rule of the ALB. Whatever the final default behavior is whenever no other rule matches, this is what is executed. This could forward to a task that gives the user a message with instructions or a fixed response as below. Another option is to forward even if it doesn't match a rule to ECS and see if docker can sort out the destination.

```
resource "aws_alb_listener" "listen1" {
  load_balancer_arn = "${aws_alb.ecs-alb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "YOU HAVE REACHED DEFAULT ACTION"
      status_code  = "400"
    }
  }
}
```

## Target Groups
A target group is used to route requests to one or more registered targets. When you create each listener rule, you specify a target group and conditions. When a rule condition is met, traffic is forwarded to the corresponding target group. Below two target group destinations are defined.

```
resource "aws_alb_target_group" "destination" {
  name     = "${var.name}-ecs"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-2e779557"
  target_type = "instance"
}

resource "aws_alb_target_group" "destination2" {
  name     = "${var.name}-ecs"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-2e779557"
  target_type = "instance"
}
```

## Listener Rules
Listener rules define the conditions by which the ALB will forward traffic to a target group. This can be based on host-header or path. Here are some examples of host-header routing.

```
resource "aws_alb_listener_rule" "new_caching_proxy" {
  listener_arn = "${aws_alb_listener.listen1.arn}"
  priority     = 1

  action {
    type = "forward"
    target_group_arn = "${aws_alb_target_group.destination.arn}"
  }

  condition {
    field  = "host-header"
    values = ["caching-proxy.dev.aetnadigital.net"]
  }
}
```

In this example, any http host header with the value of caching-proxy.dev.aetnadigital.net will forward to the specified target group called destination. Any tasks registered with this target group will be candidates to forward that traffic to.

## Task Definition
A task definition establishes the running conditions of the task for Ecs.

```
resource "aws_ecs_task_definition" "hello" {
  family = "hello"
  task_role_arn = "arn:aws:iam::898916586688:role/DevContext-Ngx-TaskRole-WA5TJYFGCZPX"

  container_definitions = <<DEFINITION
[
  {
    "cpu": 128,
    "environment": [{
      "name": "SECRET",
      "value": "KEY"
    }],
    "essential": true,
    "portMappings": [
  {
    "hostPort": 0,
    "containerPort": 80,
    "protocol": "tcp"
  }
],
    "image": "nginx:1.15.9-alpine",
    "memory": 128,
    "memoryReservation": 64,
    "name": "hello-nginx"
  }
]
DEFINITION
}
```
An important thing to point out is this is where dynamic port mapping is established. In this example you can see hostPort is set to 0. This instructs Ecs to assign the tasks to a dynamic port of its choosing that is not yet assigned. It then port maps that dynamic port to the container port, in this case port 80. When the tasks are registered with the target group, the target group sets up a health check on the dynamic port.

## Service Definition
The service is defined to control the underlying tasks. Many of these values can be populated dynamically.

```
resource "aws_ecs_service" "hello" {
  name            = "hello-nginx"
  cluster         = "arn:aws:ecs:us-east-1:898916586688:cluster/DevEcs-Cluster-1NB3QNICUB2ZV"
  task_definition = "${aws_ecs_task_definition.hello.arn}"
  desired_count   = 3

  ordered_placement_strategy {
    type  = "spread"
    field = "host"
  }

  load_balancer {
    target_group_arn = "arn:aws:elasticloadbalancing:us-east-1:898916586688:targetgroup/alb-test-ecs/1d461489db06add3"
    container_name   = "hello-nginx"
    container_port   = 80
  }

}
```
The ordered placement strategy can be switched from spread to binpack to save costs or for rolling updates of cluster nodes. The loadbalancer section links the service and underlying tasks with the ALB.

## Testing Host Header Routing
To test the loadbalancer rule based routing you can inject a host header into a curl request. To test https, use -k option.

```
curl -H "Host: caching-proxy.dev.aetnadigital.net" internal-alb-test-787710516.us-east-1.elb.amazonaws.com
```

<!-- BEGIN_TF_DOCS -->

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.8 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_alb.ecs_alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/alb) | resource |
| [aws_alb_listener.listen2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/alb_listener) | resource |
| [aws_alb_target_group.destination](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/alb_target_group) | resource |
| [aws_security_group.sg_ecs_alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_certificate_arn"></a> [certificate\_arn](#input\_certificate\_arn) | Certificate ARN. | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | The environment for the load balancer | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | The name of the load balancer | `string` | n/a | yes |
| <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups) | Security Group IDs. | `list(string)` | n/a | yes |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | Subnet IDs. | `list(string)` | n/a | yes |
| <a name="input_vpc"></a> [vpc](#input\_vpc) | The vpc for the load balancer | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_arn"></a> [alb\_arn](#output\_alb\_arn) | ALB ARN. |
| <a name="output_alb_domain_name"></a> [alb\_domain\_name](#output\_alb\_domain\_name) | ALB Domain Name. |
| <a name="output_alb_zone_id"></a> [alb\_zone\_id](#output\_alb\_zone\_id) | ALB Zone ID. |
| <a name="output_https_listener_arn"></a> [https\_listener\_arn](#output\_https\_listener\_arn) | HTTPS listener ARN. |

<!-- END_TF_DOCS -->
