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

# --- Look up existing Subnet in the VPC ---
data "aws_subnets" "existing" {
  count = length(data.aws_vpcs.existing.ids) > 0 ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [tolist(data.aws_vpcs.existing.ids)[0]]
  }

  filter {
    name   = "tag:Name"
    values = ["${var.environment}-public-subnet"]
  }
}

data "aws_subnet" "existing" {
  count = length(data.aws_vpcs.existing.ids) > 0 && length(try(data.aws_subnets.existing[0].ids, [])) > 0 ? 1 : 0
  id    = tolist(data.aws_subnets.existing[0].ids)[0]
}

# --- Look up existing Internet Gateway in the VPC ---
data "aws_internet_gateway" "existing" {
  count = length(data.aws_vpcs.existing.ids) > 0 ? 1 : 0

  filter {
    name   = "attachment.vpc-id"
    values = [tolist(data.aws_vpcs.existing.ids)[0]]
  }
}

# --- Look up existing Route Table in the VPC ---
data "aws_route_tables" "existing" {
  count = length(data.aws_vpcs.existing.ids) > 0 ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [tolist(data.aws_vpcs.existing.ids)[0]]
  }

  filter {
    name   = "tag:Name"
    values = ["${var.environment}-public-rt"]
  }
}

locals {
  vpc_exists    = length(data.aws_vpcs.existing.ids) > 0
  subnet_exists = local.vpc_exists && length(try(data.aws_subnets.existing[0].ids, [])) > 0
  igw_exists    = local.vpc_exists && length(try(data.aws_internet_gateway.existing, [])) > 0
  rt_exists     = local.vpc_exists && length(try(data.aws_route_tables.existing[0].ids, [])) > 0

  vpc_id    = local.vpc_exists ? data.aws_vpc.existing[0].id : aws_vpc.staging[0].id
  subnet_id = local.subnet_exists ? data.aws_subnet.existing[0].id : aws_subnet.public[0].id
  igw_id    = local.igw_exists ? data.aws_internet_gateway.existing[0].id : aws_internet_gateway.staging[0].id
  rt_id     = local.rt_exists ? tolist(data.aws_route_tables.existing[0].ids)[0] : aws_route_table.public[0].id
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

# --- Public Subnet (created only if not found in existing VPC) ---
resource "aws_subnet" "public" {
  count                   = local.subnet_exists ? 0 : 1
  vpc_id                  = local.vpc_id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}c"

  tags = {
    Name = "${var.environment}-public-subnet"
  }
}

# --- Internet Gateway (created only if VPC doesn't already have one) ---
resource "aws_internet_gateway" "staging" {
  count  = local.igw_exists ? 0 : 1
  vpc_id = local.vpc_id

  tags = {
    Name = "${var.environment}-igw"
  }
}

# --- Route Table (created only if not found in existing VPC) ---
resource "aws_route_table" "public" {
  count  = local.rt_exists ? 0 : 1
  vpc_id = local.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = local.igw_id
  }

  tags = {
    Name = "${var.environment}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = local.rt_exists ? 0 : 1
  subnet_id      = local.subnet_id
  route_table_id = local.rt_id
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
