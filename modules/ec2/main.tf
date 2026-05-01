terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Data source para obter a AMI mais recente do Ubuntu
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "this" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  associate_public_ip_address = var.associate_public_ip
  vpc_security_group_ids = var.vpc_security_group_ids

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    delete_on_termination = true
    encrypted             = true
  }

  monitoring              = var.environment == "prod" ? true : false
  ebs_optimized          = var.environment == "prod" ? true : false

  tags = merge(
    var.tags,
    {
      Name        = var.instance_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )

  lifecycle {
    ignore_changes = [ami]
  }
}
