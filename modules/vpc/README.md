# Módulo VPC

Módulo Terraform para criar uma VPC completa na AWS com subnets públicas, privadas, NAT Gateway e Internet Gateway.

## Recursos Criados

- VPC com suporte a DNS
- Subnets públicas e privadas em múltiplas Availability Zones
- Internet Gateway
- NAT Gateways para acesso da internet a partir de subnets privadas
- Route Tables públicas e privadas
- Network ACLs
- Elastic IPs para NAT

## Variáveis

- `vpc_cidr` - CIDR block da VPC (padrão: 10.0.0.0/16)
- `environment` - Ambiente: dev, staging, prod (obrigatório)
- `availability_zones` - AZs para as subnets (padrão: [us-east-1a, us-east-1b])
- `private_subnet_cidrs` - CIDR blocks privados (padrão: [10.0.1.0/24, 10.0.2.0/24])
- `public_subnet_cidrs` - CIDR blocks públicos (padrão: [10.0.101.0/24, 10.0.102.0/24])
- `enable_nat_gateway` - Habilitar NAT (padrão: true)
- `enable_dns_hostnames` - Habilitar DNS hostnames (padrão: true)
- `enable_dns_support` - Habilitar DNS support (padrão: true)
- `tags` - Tags adicionais (padrão: {})

## Outputs

- `vpc_id` - ID da VPC
- `vpc_cidr` - CIDR da VPC
- `internet_gateway_id` - ID do IGW
- `public_subnets` - IDs das subnets públicas
- `private_subnets` - IDs das subnets privadas
- `nat_gateway_ids` - IDs dos NAT Gateways
- `subnet_id` - ID da primeira subnet privada
