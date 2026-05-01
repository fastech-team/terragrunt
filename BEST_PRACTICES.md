# Boas Práticas para Terragrunt e Terraform

## 1. Estrutura de Módulos

Cada módulo deve ter:
- `variables.tf` - Definição de variáveis de entrada
- `main.tf` - Recursos principais
- `outputs.tf` - Outputs para consumo de outros módulos
- `README.md` - Documentação completa

```
modules/
└── exemplo/
    ├── variables.tf
    ├── main.tf
    ├── outputs.tf
    └── README.md
```

## 2. Validações de Variáveis

Sempre valide entrada de dados:

```hcl
variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment deve ser: dev, staging ou prod."
  }
}
```

## 3. Versionamento de Providers

Sempre especifique versões:

```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

## 4. Tags Automáticas

Aplique tags consistentes:

```hcl
tags = merge(
  var.tags,
  {
    Name        = "recurso-nome"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
)
```

## 5. Senhas e Dados Sensíveis

Marque como sensitive:

```hcl
variable "password" {
  type      = string
  sensitive = true
}

output "password" {
  value     = aws_db_instance.this.password
  sensitive = true
}
```

## 6. Organizando Terragrunt

```
live/
├── root-terragrunt.hcl          # Configuração global
├── prod/
│   ├── account.hcl
│   ├── environment.hcl
│   └── region/
│       └── servico/
│           └── terragrunt.hcl
└── dev/
    ├── account.hcl
    ├── environment.hcl
    └── region/
        └── servico/
            └── terragrunt.hcl
```

## 7. Remote State Seguro

Configure S3 com encrypt:

```hcl
remote_state {
  backend = "s3"
  config = {
    encrypt        = true
    bucket         = "meu-terraform-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock"
    use_lockfile   = true
  }
}
```

## 8. Dependências Entre Módulos

Use `dependency` para gerenciar ordem de criação:

```hcl
dependency "vpc" {
  config_path = "../network/vpc"
}

inputs = {
  subnet_id = dependency.vpc.outputs.subnet_id
}
```

## 9. Ambientes Configuráveis

Estruture para múltiplos ambientes:

```
live/
├── develop/
│   ├── account.hcl      # AWS ID: 111111111111
│   └── environment.hcl  # Tags dev
├── staging/
│   ├── account.hcl      # AWS ID: 222222222222
│   └── environment.hcl  # Tags staging
└── prod/
    ├── account.hcl      # AWS ID: 333333333333
    └── environment.hcl  # Tags prod
```

## 10. Documentação

Mantenha READMEs atualizados com:
- Recursos criados
- Variáveis disponíveis
- Outputs exportados
- Exemplos de uso

## 11. Monitoramento e Logging

Implemente por padrão:
- CloudWatch Logs
- CloudWatch Alarms em produção
- Tags para cost allocation
- Audit logging ativado

## 12. Ciclo de Vida

Use lifecycle para recursos críticos:

```hcl
lifecycle {
  create_before_destroy = true
  ignore_changes = [password]
  prevent_destroy = true  # Produção
}
```

## 13. Data Sources

Use data sources para dados existentes:

```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04*"]
  }
}
```

## 14. Conditional Logic

Crie recursos opcionais com count ou for_each:

```hcl
resource "aws_nat_gateway" "this" {
  count         = var.enable_nat_gateway ? length(var.availability_zones) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
}
```

## 15. Outputs bem estruturados

Exponha apenas o necessário:

```hcl
output "vpc_id" {
  description = "ID da VPC"
  value       = aws_vpc.this.id
}

output "private_ip" {
  description = "IP privado da instância"
  value       = aws_instance.this.private_ip
  sensitive   = true  # Se necessário
}
```
