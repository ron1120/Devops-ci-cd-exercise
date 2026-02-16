# =============================================================================
# Terraform - Input Variables
# =============================================================================

variable "aws_region" {
  description = "AWS region for staging deployment"
  type        = string
  default     = "us-east-2"
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
  default     = "aws_key"
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

variable "enable_eip" {
  description = "Whether to allocate an Elastic IP for the instance. Set to false if you hit the EIP address limit."
  type        = bool
  default     = false
}

variable "vpc_name" {
  description = "Name tag for the VPC. If a VPC with this name already exists it will be reused instead of creating a new one."
  type        = string
  default     = "staging-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC (used only when creating a new VPC)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}
