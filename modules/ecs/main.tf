terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "this" {
  name = var.cluster_name

  tags = merge(
    var.tags,
    {
      Name        = var.cluster_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

# ECS Cluster Capacity Providers
resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name = aws_ecs_cluster.this.name

  capacity_providers = var.capacity_providers

  default_capacity_provider_strategy {
    for_each = { for s in var.default_capacity_provider_strategy : s.capacity_provider => s }

    capacity_provider = each.key
    weight            = each.value.weight
    base              = each.value.base
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.cluster_name}"
  retention_in_days = var.log_group_retention_days

  tags = merge(
    var.tags,
    {
      Name        = "ecs-logs-${var.cluster_name}"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

# ECS Cluster Settings (Container Insights)
resource "aws_ecs_cluster_setting" "container_insights" {
  count           = var.enable_container_insights ? 1 : 0
  name            = "containerInsights"
  value           = "enabled"
  cluster_name    = aws_ecs_cluster.this.name
}

# IAM Role para ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.cluster_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = "${var.cluster_name}-ecs-task-execution-role"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

# Attach policy para task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM Role para ECS Task (aplicação)
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.cluster_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = "${var.cluster_name}-ecs-task-role"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}
