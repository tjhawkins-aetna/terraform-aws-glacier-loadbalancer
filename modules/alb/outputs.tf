output "https_listener_arn" {
  value       = aws_alb_listener.listen2.arn
  description = "HTTPS listener ARN."
}

output "alb_domain_name" {
  value       = aws_alb.ecs_alb.dns_name
  description = "ALB Domain Name."
}

output "alb_zone_id" {
  value       = aws_alb.ecs_alb.zone_id
  description = "ALB Zone ID."
}

output "alb_arn" {
  value       = aws_alb.ecs_alb.arn
  description = "ALB ARN."
}
