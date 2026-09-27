## PROVIDES ##
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.55.0"
    }
  }
}

## LOCAL VALUES ##
locals {
  ecr_registry = "${var.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}

# create lifecycle rule for task repository in Amazon ECR
resource "aws_ecr_lifecycle_policy" "policy" {
  for_each = var.container_definitions

  repository = "${var.registry}/${each.key}"
  policy     = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep last 5 images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 5
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
  depends_on = [data.aws_ecr_repository.repo]
}

## -------------------------| RESOURCES |------------------------- ##

# Task definition is a text file that describes one or more containers that form your application
resource "aws_ecs_task_definition" "task" {
  for_each = var.container_definitions

  family                   = each.key
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  execution_role_arn       = data.aws_iam_role.execution_role.arn
  task_role_arn            = data.aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name   = each.key
    image  = "${local.ecr_registry}/${var.registry}/${each.key}:${var.image_tag}"
    cpu    = each.value.cpu
    memory = each.value.memory
    portMappings = [
      {
        containerPort = each.value.container_port
        protocol      = "tcp"
      }
    ]
    essential   = true
    environment = lookup(var.task_variables, each.key, [])
    secrets = concat(
      [for env_name, secret_key in var.global_secrets : {
        name      = env_name
        valueFrom = "${data.aws_secretsmanager_secret.global.arn}:${secret_key}::"
      }],
      [for env_name, secret_key in lookup(var.task_secrets, each.key, {}) : {
        name      = env_name
        valueFrom = "${data.aws_secretsmanager_secret.task[each.key].arn}:${secret_key}::"
      }]
    )
    environmentFiles = []
    mountPoints      = []
    volumesFrom      = []
    ulimits          = []
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.log[each.key].name
        awslogs-create-group  = "true"
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])

}

resource "aws_cloudwatch_log_group" "log" {
  for_each          = var.container_definitions
  name              = "/ecs/${each.key}"
  retention_in_days = var.log_retention_days
}

# Service to run and maintain your desired number of tasks simultaneously in an ECS cluster
resource "aws_ecs_service" "service" {
  for_each = var.container_definitions

  name                 = each.key
  cluster              = data.aws_ecs_cluster.cluster.arn
  task_definition      = aws_ecs_task_definition.task[each.key].arn
  scheduling_strategy  = "REPLICA"
  desired_count        = each.value.desired_count
  force_new_deployment = true

  network_configuration {
    subnets          = var.subnets_id
    security_groups  = [aws_security_group.task.id]
    assign_public_ip = false
  }
  depends_on = [aws_lb_listener_rule.rule, aws_lb_listener_rule.internal_rule]

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group[each.key].arn
    container_name   = each.key
    container_port   = each.value.container_port
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.internal_target_group[each.key].arn
    container_name   = each.key
    container_port   = each.value.container_port
  }
}

resource "aws_security_group" "task" {
  name_prefix = "${var.cluster_name}-ecs-tasks"
  description = "Acesso dos ALBs as tasks nas portas 80 e 443"
  vpc_id      = var.vpc_id
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = concat(tolist(data.aws_lb.alb.security_groups), tolist(data.aws_lb.internal_alb.security_groups))
  }
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = concat(tolist(data.aws_lb.alb.security_groups), tolist(data.aws_lb.internal_alb.security_groups))
  }
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

# defines forwarding rule conditions
resource "aws_lb_listener_rule" "rule" {
  for_each = var.container_definitions

  listener_arn = data.aws_lb_listener.https.arn
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group[each.key].arn
  }
  condition {
    path_pattern {
      values = ["/${each.key}/*"]
    }
  }
}

# Adicionar regra para o segundo ALB (sempre criar regra para o ALB interno quando público é true)
resource "aws_lb_listener_rule" "internal_rule" {
  for_each = var.container_definitions

  listener_arn = data.aws_lb_listener.internal_https.arn
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal_target_group[each.key].arn
  }
  condition {
    path_pattern {
      values = ["/${each.key}/*"]
    }
  }
}

# Provides a Target Group resource for use with Load Balancer
resource "aws_lb_target_group" "target_group" {
  for_each = var.container_definitions

  name_prefix = "tg-ext-${each.key}"
  port        = each.value.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  health_check {
    healthy_threshold   = "5"
    interval            = "60"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "5"
    path                = var.health_path
    unhealthy_threshold = "5"
  }
  lifecycle {
    create_before_destroy = true
  }
}

# Target Group para o ALB interno quando public_alb=true
resource "aws_lb_target_group" "internal_target_group" {
  for_each = var.container_definitions

  name_prefix = "tg-int-${each.key}"
  port        = each.value.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  health_check {
    healthy_threshold   = "5"
    interval            = "60"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "5"
    path                = var.health_path
    unhealthy_threshold = "5"
  }
  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_appautoscaling_target" "ecs_target" {
  for_each = var.container_definitions

  max_capacity       = each.value.max_tasks
  min_capacity       = each.value.min_tasks
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.service[each.key].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Política de auto scaling baseada em CPU
resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  for_each = var.container_definitions

  name               = "ecs-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = each.value.cpu_target_scaling # Escala task se utilização média de CPU for > 70%
    scale_in_cooldown  = 300                           # tempo de espera entre redução de escala
    scale_out_cooldown = 300                           # tempo de espera entre aumento de escala
    disable_scale_in   = false                         # permite reduzir tarefas se estiver abaixo da métrica
  }
}

# Política de auto scaling baseada em memória
resource "aws_appautoscaling_policy" "ecs_policy_memory" {
  for_each = var.container_definitions

  name               = "ecs-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = each.value.mem_target_scaling
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
    disable_scale_in   = false

  }
}

## DATA SOURCES ##
data "aws_secretsmanager_secret" "global" {
  name = var.global_secret_name
}

data "aws_secretsmanager_secret" "task" {
  for_each = var.container_definitions
  name     = each.key
}

data "aws_ecs_cluster" "cluster" {
  cluster_name = var.cluster_name
}

data "aws_iam_role" "execution_role" {
  name = "${var.cluster_name}-ecsTaskExecutionRole"
}
data "aws_iam_role" "ecs_task_role" {
  name = "${var.cluster_name}-ECSTaskRole"
}
data "aws_acm_certificate" "acm_cert" {
  domain   = "*.${var.domain}"
  statuses = ["ISSUED"]
}
data "aws_lb" "alb" {
  name = var.load_balancer
}
data "aws_lb" "internal_alb" {
  name = var.internal_load_balancer
}
data "aws_lb_listener" "https" {
  load_balancer_arn = data.aws_lb.alb.arn
  port              = 443
}
data "aws_lb_listener" "internal_https" {
  load_balancer_arn = data.aws_lb.internal_alb.arn
  port              = 443
}
data "aws_ecr_repository" "repo" {
  for_each = var.container_definitions
  name     = "${var.registry}/${each.key}"
}
