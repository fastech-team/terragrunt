# Projeto de Infraestrutura com Terragrunt

Projeto completo de infraestrutura como código na AWS usando Terragrunt e Terraform com boas práticas, modularização e segurança.

## 📋 Estrutura do Projeto

```
terragrunt/
├── README.md                     # Este arquivo
├── BEST_PRACTICES.md            # Guia de boas práticas
├── CHANGELOG.md                 # Histórico de mudanças
├── PRODUCTION_GUIDE.md          # Guia de produção
├── QUICK_REFERENCE.md           # Mapa de referência rápida
├── SUMMARY.md                   # Resumo de melhorias
├── root.hcl                     # Configuração raiz global
├── terraform.tfvars.example     # Exemplo de configuração
├── validate.sh                  # Script de validação
├── .gitignore                   # Arquivos ignorados
├── develop/                     # Ambiente de desenvolvimento
│   ├── account.hcl              # Variáveis de conta AWS
│   ├── environment.hcl          # Variáveis de ambiente
│   └── us-east-1/
│       ├── region.hcl           # Variáveis de região
│       ├── compute/
│       │   └── ec2-metabase/
│       │       └── terragrunt.hcl
│       ├── containers/
│       │   └── ecs/
│       │       └── terragrunt.hcl
│       ├── database/
│       │   └── rds/
│       │       └── terragrunt.hcl
│       ├── network/
│       │   └── vpc/
│       │       └── terragrunt.hcl
│       └── storage/
│           └── s3/
│               └── terragrunt.hcl
├── prod/                        # Ambiente de produção
│   ├── account.hcl              # Variáveis de conta AWS (prod)
│   ├── environment.hcl          # Variáveis de ambiente (prod)
│   └── us-east-1/
│       ├── region.hcl           # Variáveis de região
│       ├── compute/
│       │   └── ec2-metabase/
│       │       └── terragrunt.hcl
│       ├── containers/
│       │   └── ecs/
│       │       └── terragrunt.hcl
│       ├── database/
│       │   └── rds/
│       │       └── terragrunt.hcl
│       ├── network/
│       │   └── vpc/
│       │       └── terragrunt.hcl
│       └── storage/
│           └── s3/
│               └── terragrunt.hcl
└── modules/                     # Módulos Terraform reutilizáveis
    ├── ec2/
    │   ├── variables.tf
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── README.md
    ├── vpc/
    │   ├── variables.tf
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── README.md
    ├── s3/
    │   ├── variables.tf
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── README.md
    ├── ecs/
    │   ├── variables.tf
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── README.md
    └── rds/
        ├── variables.tf
        ├── main.tf
        ├── outputs.tf
        └── README.md
```
    │   ├── variables.tf
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── README.md
    └── rds/
        ├── variables.tf
        ├── main.tf
        ├── outputs.tf
        └── README.md
```

## 🚀 Recursos Criados

### 1. **VPC** (Módulo VPC)
- VPC com suporte a DNS
- Subnets públicas e privadas em múltiplas AZs
- Internet Gateway
- NAT Gateways
- Route Tables
- Network ACLs

### 2. **EC2** (Módulo EC2)
- Instâncias EC2 com Ubuntu 22.04
- Volume raiz criptografado
- Monitoramento em produção
- EBS otimizado

### 3. **S3** (Módulo S3)
- Buckets privados
- Versionamento
- Criptografia AES256/KMS
- Block Public Access
- Logging (opcional)
- Ciclo de vida (opcional)

### 4. **ECS** (Módulo ECS)
- Cluster ECS
- Capacity Providers (FARGATE, FARGATE_SPOT)
- CloudWatch Logs
- Container Insights (opcional)
- IAM Roles

### 5. **RDS** (Módulo RDS)
- Suporte a MySQL, PostgreSQL, MariaDB, Oracle, SQL Server
- Criptografia de armazenamento
- Multi-AZ (opcional)
- Backups automáticos
- CloudWatch Alarms
- Parameter e Option Groups

## ⚙️ Configuração Inicial

### 1. Configure Credenciais AWS

```develop/us-east-1/network/vpc
terragrunt init
```

### Validar Configuração

```bash
cd develop
terragrunt validate-all
```

### Planejar Deploy (dry-run)

```bash
cd develop
terragrunt plan-all
```

### Aplicar Configuração

```bash
cd develop/us-east-1/network/vpc
terragrunt apply
```

Para aplicar tudo:
```bash
cd develop
terragrunt apply-all
```

### Destruir Recursos

```bash
cd 
cd live/develop/us-east-1/network/vpc
terragrunt init
```

### Validar Configuração

```bash
cd live/develop
terragrunt validate-all
```

### Planejar Deploy (dry-run)

```bash
cd live/develop
terragrunt plan-all
```

### Aplicar Configuração

```bash
cd live/develop/us-east-1/network/vpc
terragrunt apply
```

Para aplicar tudo:
```bash
cd live/develop
terragrunt apply-all
```

### Destruir Recursos

```bash
cd live/develop
terragrunt destroy-all
```

## 🔐 Boas Práticas Implementadas

✅ **Segurança**
- Criptografia habilitada por padrão
- Block Public Access em S3
- Deletion protection em produção
- Senhas como sensíveis

✅ **Organização**
- Modularização clara (variables.tf, main.tf, outputs.tf)
- Documentação em cada módulo
- READMEs estruturados

✅ **Validação**
- Validação de variáveis (environment, engine, etc.)
- Versionamento de providers
- Ciclo de vida controlado

✅ **Configuração**
- Remote state em S3 com encrypt
- Includes padronizados
- Separação clara de ambientes

✅ **Tags**
- Tags automáticas
- Environment identificado
- ManagedBy e timestamp

✅ **Monitoramento**
- CloudWatch Logs
- Alarms em produção
- Container Insights disponível

## 🔗 Dependências

- **EC2 Metabase** → VPC (subnet_id)
- **RDS** → VPC (security groups)
- **ECS** → VPC (security groups)
- **S3** → Independente

## 📝 Exemplos de Uso

### Criar Stack Completa de Dev

```bash
cd live/develop
terragrunt plan-all   # Visualizar
terragrunt apply-all  # Criar
```

### Modificar Ambiente

Edite `live/develop/environment.hcl`:
```hcl
locals {
  environment = "dev"
}

inputs = {
  environment = local.environment
  tags = {
    Environment = local.environment
    CostCenter  = "DevTeam"
    AutoOff     = "true"
  }
}
```

### Ler Outputs

```bash
cd live/develop/us-east-1/network/vpc
terragrunt output vpc_id
```

## 🐛 Troubleshooting

| Erro | Solução |
|------|---------|
| "find_in_parent_folders" não encontra arquivo | Verificar hierarquia de diretórios |
| "bucket already exists" | Usar nome único globalmente |
| "subnet does not exist" | Criar VPC primeiro com `dependency` |
| "security group not found" | Adicionar subnet_id ou security_group_ids |

## 📚 Documentação Adicional

- [BEST_PRACTICES.md](BEST_PRACTICES.md) - Guia detalhado de boas práticas
- [CHANGELOG.md](CHANGELOG.md) - Histórico de mudanças
- [modules/ec2/README.md](modules/ec2/README.md) - Módulo EC2
- [modules/vpc/README.md](modules/vpc/README.md) - Módulo VPC
- [modules/s3/README.md](modules/s3/README.md) - Módulo S3
- [modules/ecs/README.md](modules/ecs/README.md) - Módulo ECS
- [modules/rds/README.md](modules/rds/README.md) - Módulo RDS

## 🤝 Contribuindo

1. Manter estrutura de diretórios consistente
2. Adicionar documentação (README.md)
3. Implementar validações de variáveis
4. Seguir padrão de tags
5. Testar com `terragrunt plan` antes de `apply`

## 📄 Licença

Este projeto está disponível sob a licença MIT.
cd meu-projeto/dev

# Aplique todos os recursos de uma vez
terragrunt run-all apply

# Ou aplique individualmente cada recurso
cd resources/s3-bucket01
terragrunt apply

cd ../s3-bucket02
terragrunt apply

cd ../ec2-metabase
terragrunt apply
```

4. **Comandos úteis:**
```bash
# Ver o plano de todos os recursos
terragrunt run-all plan

# Ver apenas um recurso específico
cd resources/ec2-metabase
terragrunt plan

# Destruir todos os recursos
terragrunt run-all destroy

# Destruir apenas um recurso
cd resources/ec2-metabase
terragrunt destroy        
```
