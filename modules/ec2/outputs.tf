output "instance_id" {
  description = "ID da instância EC2"
  value       = aws_instance.this.id
}

output "instance_arn" {
  description = "ARN da instância EC2"
  value       = aws_instance.this.arn
}

output "private_ip" {
  description = "IP privado da instância"
  value       = aws_instance.this.private_ip
}

output "public_ip" {
  description = "IP público da instância"
  value       = aws_instance.this.public_ip
}

output "primary_network_interface_id" {
  description = "ID do network interface primário"
  value       = aws_instance.this.primary_network_interface_id
}

output "instance_state" {
  description = "Estado da instância"
  value       = aws_instance.this.instance_state
}
