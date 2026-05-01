terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# VPC
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(
    var.tags,
    {
      Name        = "vpc-${var.environment}"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

# Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name        = "igw-${var.environment}"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

# Subnets Públicas
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index % length(var.availability_zones)]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name        = "public-subnet-${count.index + 1}"
      Environment = var.environment
      Type        = "Public"
      ManagedBy   = "Terraform"
    }
  )
}

# Subnets Privadas
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]

  tags = merge(
    var.tags,
    {
      Name        = "private-subnet-${count.index + 1}"
      Environment = var.environment
      Type        = "Private"
      ManagedBy   = "Terraform"
    }
  )
}

# Elastic IPs para NAT Gateway
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? length(var.availability_zones) : 0
  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name        = "eip-nat-${count.index + 1}"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )

  depends_on = [aws_internet_gateway.this]
}

# NAT Gateway
resource "aws_nat_gateway" "this" {
  count         = var.enable_nat_gateway ? length(var.availability_zones) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    var.tags,
    {
      Name        = "nat-${count.index + 1}"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )

  depends_on = [aws_internet_gateway.this]
}

# Route Table Pública
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block      = "0.0.0.0/0"
    gateway_id      = aws_internet_gateway.this.id
  }

  tags = merge(
    var.tags,
    {
      Name        = "rt-public"
      Environment = var.environment
      Type        = "Public"
      ManagedBy   = "Terraform"
    }
  )
}

# Associação: Route Table Pública com Subnets Públicas
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route Tables Privadas
resource "aws_route_table" "private" {
  count  = var.enable_nat_gateway ? length(var.availability_zones) : 0
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[count.index].id
  }

  tags = merge(
    var.tags,
    {
      Name        = "rt-private-${count.index + 1}"
      Environment = var.environment
      Type        = "Private"
      ManagedBy   = "Terraform"
    }
  )
}

# Associação: Route Tables Privadas com Subnets Privadas
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index % length(aws_route_table.private)].id
}

# Network ACL para segurança adicional
resource "aws_network_acl" "main" {
  vpc_id     = aws_vpc.this.id
  subnet_ids = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)

  # Inbound rules
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  # Outbound rules
  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(
    var.tags,
    {
      Name        = "nacl-${var.environment}"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}
