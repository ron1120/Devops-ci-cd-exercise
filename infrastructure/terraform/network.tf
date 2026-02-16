# =============================================================================
# Terraform - Networking (VPC, Subnet, Security Groups)
# =============================================================================

# --- Look up existing VPC by name tag ---
data "aws_vpcs" "existing" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

# Fetch full details of the existing VPC (if found)
data "aws_vpc" "existing" {
  count = length(data.aws_vpcs.existing.ids) > 0 ? 1 : 0
  id    = tolist(data.aws_vpcs.existing.ids)[0]
}

locals {
  vpc_exists = length(data.aws_vpcs.existing.ids) > 0
  vpc_id     = local.vpc_exists ? data.aws_vpc.existing[0].id : aws_vpc.staging[0].id
}

# --- VPC (created only if one with the same name doesn't exist) ---
resource "aws_vpc" "staging" {
  count                = local.vpc_exists ? 0 : 1
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

# --- Public Subnet ---
resource "aws_subnet" "public" {
  vpc_id                  = local.vpc_id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}c"

  tags = {
    Name = "${var.environment}-public-subnet"
  }
}

# --- Internet Gateway ---
resource "aws_internet_gateway" "staging" {
  vpc_id = local.vpc_id

  tags = {
    Name = "${var.environment}-igw"
  }
}

# --- Route Table ---
resource "aws_route_table" "public" {
  vpc_id = local.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.staging.id
  }

  tags = {
    Name = "${var.environment}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# --- Security Group ---
resource "aws_security_group" "app" {
  name_prefix = "${var.environment}-app-"
  vpc_id      = local.vpc_id
  description = "Security group for staging application"

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
    description = "SSH access"
  }

  # Application port
  ingress {
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Application access"
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "${var.environment}-app-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}
