# =============================================================================
# Terraform - Outputs
# =============================================================================

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.app.id
}

output "instance_public_ip" {
  description = "Elastic IP address of the staging server"
  value       = aws_eip.app.public_ip
}

output "instance_public_dns" {
  description = "Public DNS of the staging server"
  value       = aws_eip.app.public_dns
}

output "app_url" {
  description = "URL to access the application"
  value       = "http://${aws_eip.app.public_ip}:${var.app_port}"
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${aws_eip.app.public_ip}"
}

output "vpc_id" {
  description = "VPC ID"
  value       = local.vpc_id
}

output "vpc_reused" {
  description = "Whether an existing VPC was reused"
  value       = local.vpc_exists
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.app.id
}
