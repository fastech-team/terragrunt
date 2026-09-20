terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.55.0"
    }
  }
}

## LOCAL VALUES ##

locals {
  alb_ingress_rules = flatten([
    # primeiro for percorre cada Load Balancer
    # segundo for percorre cada regra daquele ALB.
    # para cada regra econtrada gera um objeto novo.
    for lb_name, lb in var.load_balancers : [
      for rule_name, rule in lb.ingress_rules : {
        key     = "${lb_name}-${rule_name}"
        lb_name = lb_name

        port         = rule.port
        protocol     = rule.protocol
        allowed_cidr = rule.allowed_cidr
      }
    ]
  ])
}

# ECS Cluster fargate
resource "aws_ecs_cluster" "cluster" {
  name = var.cluster_name
  setting {
    name  = "containerInsights"
    value = var.enable_container_insights
  }
}

# ECS Cluster Capacity Providers
resource "aws_ecs_cluster_capacity_providers" "providers" {
  cluster_name       = aws_ecs_cluster.cluster.name
  capacity_providers = try(var.capacity_providers, ["FARGATE", "FARGATE_SPOT"])

  default_capacity_provider_strategy {
    capacity_provider = try(var.capacity_provider_strategy.capacity_provider, "FARGATE")
    weight            = try(var.capacity_provider_strategy.weight, 100)
    base              = try(var.capacity_provider_strategy.base, 1)
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

# IAM Role para ECS Task Execution
resource "aws_iam_role" "execution_role" {
  name = "${var.cluster_name}-ecsTaskExecutionRole"

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
      Name        = "${var.cluster_name}-ecsTaskExecutionRole"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

# Attach policy para task execution
resource "aws_iam_role_policy_attachment" "execution_role" {
  role       = aws_iam_role.execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "execution_role_secrets" {
  name = "${var.cluster_name}-ecs-task-secrets"
  role = aws_iam_role.execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
        Resource = "arn:aws:secretsmanager:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:secret:${var.cluster_name}/${var.environment}/*"
    }]
  })
}

# IAM Role para ECS Task (aplicação)
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.cluster_name}-ECSTaskRole"

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
}

resource "aws_iam_policy" "ecs_task_role" {
  name        = "${var.cluster_name}-ecs-task-policy"
  path        = "/"
  description = "Policy for ECS Task Role"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "ses:SendRawEmail",
          "ses:SendEmail"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}
# Attach policy para ecs task role 
resource "aws_iam_role_policy_attachment" "ecs_task_role" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_role.arn
  depends_on = [aws_iam_role.ecs_task_role, aws_iam_policy.ecs_task_role]
}

# External and Internal Application Load Balancer to ECS Fargate services
resource "aws_lb" "alb" {
  for_each = var.load_balancers

  name               = "alb-${var.cluster_name}-${each.key}"
  internal           = each.value.internal
  load_balancer_type = each.value.load_balancer_type

  subnets         = each.value.subnets
  security_groups = [aws_security_group.alb[each.key].id]

}
# security group for ECS 
resource "aws_security_group" "alb" {
  for_each = var.load_balancers

  name        = "SecGroup-${var.cluster_name}-${each.key}"
  description = "Allow all traffic to ALB ${each.key}"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  lifecycle {
    create_before_destroy = true
  }
}
# security group ingress rule for ECS services
resource "aws_vpc_security_group_ingress_rule" "ingress" {
  for_each = {
    for rule in local.alb_ingress_rules :
    rule.key => rule
  }

  security_group_id = aws_security_group.alb[each.value.lb_name].id
  description       = "Ingress para listener ${each.key}"

  from_port   = each.value.port
  to_port     = each.value.port
  ip_protocol = lower(each.value.protocol)
  cidr_ipv4   = each.value.allowed_cidr
}

## DATA SOURCES ##
data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_acm_certificate" "cert" {
  count    = var.domain != "" ? 1 : 0
  domain   = "*.${var.domain}"
  statuses = ["ISSUED"]
}