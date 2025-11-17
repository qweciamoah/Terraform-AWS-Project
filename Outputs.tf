output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.techcorp.id
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = aws_lb.app_lb.dns_name
}

output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = aws_eip.bastion_eip.public_ip
}
