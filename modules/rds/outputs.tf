output "db_instance_id" {
  description = "ID da instância RDS"
  value       = aws_db_instance.this.id
}

output "db_instance_arn" {
  description = "ARN da instância RDS"
  value       = aws_db_instance.this.arn
}

output "db_instance_endpoint" {
  description = "Endpoint da instância RDS"
  value       = aws_db_instance.this.endpoint
  sensitive   = true
}

output "db_instance_address" {
  description = "Endereço da instância RDS"
  value       = aws_db_instance.this.address
  sensitive   = true
}

output "db_instance_port" {
  description = "Porta da instância RDS"
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Nome do banco de dados"
  value       = aws_db_instance.this.db_name
}

output "db_username" {
  description = "Usuário mestre"
  value       = aws_db_instance.this.username
  sensitive   = true
}

output "db_parameter_group_id" {
  description = "ID do parameter group"
  value       = aws_db_parameter_group.this.id
}

output "db_option_group_id" {
  description = "ID do option group"
  value       = aws_db_option_group.this.id
}

output "db_engine" {
  description = "Engine do banco"
  value       = aws_db_instance.this.engine
}

output "db_engine_version" {
  description = "Versão do engine"
  value       = aws_db_instance.this.engine_version
}

output "multi_az" {
  description = "Status Multi-AZ"
  value       = aws_db_instance.this.multi_az
}
