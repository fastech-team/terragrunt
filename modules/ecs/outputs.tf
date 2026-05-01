output "cluster_id" {
  description = "ID do cluster ECS"
  value       = aws_ecs_cluster.this.id
}

output "cluster_name" {
  description = "Nome do cluster ECS"
  value       = aws_ecs_cluster.this.name
}

output "cluster_arn" {
  description = "ARN do cluster ECS"
  value       = aws_ecs_cluster.this.arn
}

output "log_group_name" {
  description = "Nome do CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.ecs_logs.name
}

output "log_group_arn" {
  description = "ARN do CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.ecs_logs.arn
}

output "ecs_task_execution_role_arn" {
  description = "ARN do IAM role de execução de tasks"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_task_role_arn" {
  description = "ARN do IAM role de tasks"
  value       = aws_iam_role.ecs_task_role.arn
}

output "capacity_providers" {
  description = "Capacity providers configurados"
  value       = var.capacity_providers
}
