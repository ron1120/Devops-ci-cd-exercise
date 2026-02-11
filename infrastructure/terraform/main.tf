# =============================================================================
# Terraform - AWS Provider Configuration
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state in S3 (uncomment and configure for team use)
  # backend "s3" {
  #   bucket         = "devops-ci-cd-terraform-state"
  #   key            = "staging/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "devops-ci-cd-exercise"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
