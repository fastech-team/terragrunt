terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# RDS Instance
resource "aws_db_instance" "this" {
  identifier            = var.db_identifier
  db_name              = var.db_name
  engine               = var.engine
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  allocated_storage    = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage

  username = var.username
  password = var.password

  db_subnet_group_name   = var.db_subnet_group_name != "" ? var.db_subnet_group_name : null
  vpc_security_group_ids = length(var.vpc_security_group_ids) > 0 ? var.vpc_security_group_ids : null

  multi_az               = var.multi_az
  publicly_accessible    = var.publicly_accessible
  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window     = var.maintenance_window

  storage_encrypted             = true
  enable_cloudwatch_logs_exports = var.enable_cloudwatch_logs_exports

  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.db_identifier}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  deletion_protection = var.environment == "prod" ? true : false
  enabled_cloudwatch_logs_exports = var.enable_cloudwatch_logs_exports

  tags = merge(
    var.tags,
    {
      Name        = var.db_identifier
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )

  lifecycle {
    ignore_changes = [
      engine_version,
      password
    ]
  }
}

# Parameter Group
resource "aws_db_parameter_group" "this" {
  family      = "${var.engine}${split(".", var.engine_version)[0]}"
  name_prefix = "${var.db_identifier}-"

  tags = merge(
    var.tags,
    {
      Name        = "${var.db_identifier}-params"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# DB Option Group
resource "aws_db_option_group" "this" {
  name_prefix             = "${var.db_identifier}-"
  option_group_description = "Option group for ${var.db_identifier}"
  engine_name              = var.engine
  major_engine_version     = split(".", var.engine_version)[0]

  tags = merge(
    var.tags,
    {
      Name        = "${var.db_identifier}-options"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# CloudWatch Alarms para monitoramento
resource "aws_cloudwatch_metric_alarm" "db_cpu" {
  count               = var.environment == "prod" ? 1 : 0
  alarm_name          = "${var.db_identifier}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Alerta quando CPU é maior que 80%"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.this.identifier
  }
}

resource "aws_cloudwatch_metric_alarm" "db_storage" {
  count               = var.environment == "prod" ? 1 : 0
  alarm_name          = "${var.db_identifier}-low-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "2147483648" # 2 GB em bytes
  alarm_description   = "Alerta quando espaço livre é menor que 2GB"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.this.identifier
  }
}
