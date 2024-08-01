output "listener_arn" {
  value       = aws_alb_listener.listen.arn
  description = "Listener ARN."
}

output "alb_domain_name" {
  value       = aws_alb.ec2_alb.dns_name
  description = "ALB DNS name."
}

output "alb_zone_id" {
  value       = aws_alb.ec2_alb.zone_id
  description = "ALB Zone ID."
}

output "alb_arn" {
  value       = aws_alb.ec2_alb.arn
  description = "ALB ARN."
}
