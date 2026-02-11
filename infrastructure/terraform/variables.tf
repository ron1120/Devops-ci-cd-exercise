# =============================================================================
# Terraform - Input Variables
# =============================================================================

variable "aws_region" {
  description = "AWS region for staging deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
  default     = "staging"
}

variable "instance_type" {
  description = "EC2 instance type for staging"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "SSH key pair name for EC2 access"
  type        = string
}

variable "app_port" {
  description = "Port the application listens on"
  type        = number
  default     = 5000
}

variable "docker_image" {
  description = "Docker image to deploy (e.g., ronsss/devops-testing-app:latest)"
  type        = string
  default     = "ronsss/devops-testing-app:latest"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed for SSH access"
  type        = string
  default     = "0.0.0.0/0"
}
