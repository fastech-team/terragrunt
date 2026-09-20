output "cluster_id" {
  description = "ID do cluster ECS"
  value       = aws_ecs_cluster.cluster.id
}

output "cluster_name" {
  description = "Nome do cluster ECS"
  value       = aws_ecs_cluster.cluster.name
}

output "cluster_arn" {
  description = "ARN do cluster ECS"
  value       = aws_ecs_cluster.cluster.arn
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
  value       = aws_iam_role.execution_role.arn
}

output "ecs_task_role_arn" {
  description = "ARN do IAM role de tasks"
  value       = aws_iam_role.ecs_task_role.arn
}

output "aws_lb_name" {
  description = "Nome do Load Balancer"
  value       = { for lb_name, lb in aws_lb.alb : lb_name => lb.name }
}

output "aws_lb_arn" {
  description = "ARN do Load Balancer"
  value       = { for lb_name, lb in aws_lb.alb : lb_name => lb.arn }
}

output "aws_security_group_id" {
  description = "ID do Security Group"
  value       = { for sg_name, sg in aws_security_group.alb : sg_name => sg.id }
}

output "capacity_providers" {
  description = "Capacity providers configurados"
  value       = aws_ecs_cluster_capacity_providers.providers.capacity_providers
}
