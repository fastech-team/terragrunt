output "vpc_id" {
  description = "ID da VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR block da VPC"
  value       = aws_vpc.this.cidr_block
}

output "internet_gateway_id" {
  description = "ID do Internet Gateway"
  value       = aws_internet_gateway.this.id
}

output "public_subnets" {
  description = "IDs das subnets públicas"
  value       = aws_subnet.public[*].id
}

output "private_subnets" {
  description = "IDs das subnets privadas"
  value       = aws_subnet.private[*].id
}

output "public_subnet_cidrs" {
  description = "CIDR blocks das subnets públicas"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidrs" {
  description = "CIDR blocks das subnets privadas"
  value       = aws_subnet.private[*].cidr_block
}

output "nat_gateway_ids" {
  description = "IDs dos NAT Gateways"
  value       = try(aws_nat_gateway.this[*].id, [])
}

output "nat_gateway_ips" {
  description = "IPs dos NAT Gateways"
  value       = try(aws_eip.nat[*].public_ip, [])
}

output "public_route_table_id" {
  description = "ID da route table pública"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "IDs das route tables privadas"
  value       = try(aws_route_table.private[*].id, [])
}

output "subnet_id" {
  description = "ID da primeira subnet privada (para uso em módulos)"
  value       = aws_subnet.private[0].id
}
