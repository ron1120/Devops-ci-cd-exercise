# =============================================================================
# Terraform - EC2 Instance
# =============================================================================

# --- Latest Amazon Linux 2023 AMI ---
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# --- EC2 Instance ---
resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.app.id]

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Update system
    dnf update -y

    # Install Docker
    dnf install -y docker
    systemctl enable docker
    systemctl start docker

    # Install Python3 (for Ansible managed_by scripts if needed)
    dnf install -y python3 python3-pip

    # Add ec2-user to docker group
    usermod -aG docker ec2-user

    # Signal that user_data completed
    touch /tmp/user_data_complete
  EOF

  tags = {
    Name        = "${var.environment}-app-server"
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  # Wait for instance to be ready
  lifecycle {
    create_before_destroy = false
  }
}

# --- Elastic IP (optional, for stable IP) ---
resource "aws_eip" "app" {
  instance = aws_instance.app.id
  domain   = "vpc"

  tags = {
    Name = "${var.environment}-app-eip"
  }
}
