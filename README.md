# Projeto de Infraestrutura com Terragrunt

Projeto completo de infraestrutura como código na AWS usando Terragrunt e Terraform com boas práticas, modularização e segurança.

## 📋 Estrutura do Projeto

```
terragrunt/
├── README.md                     # Este arquivo
├── BEST_PRACTICES.md            # Guia de boas práticas
├── CHANGELOG.md                 # Histórico de mudanças
├── live/                        # Configurações Terragrunt
│   ├── root-terragrunt.hcl      # Configuração raiz global
│   └── develop/
│       ├── account.hcl          # Variáveis de conta AWS
│       ├── environment.hcl      # Variáveis de ambiente
│       └── us-east-1/
│           ├── region.hcl       # Variáveis de região
│           ├── compute/
│           │   └── ec2-metabase/
│           │       └── terragrunt.hcl
│           ├── containers/
│           │   └── ecs/
│           │       └── terragrunt.hcl
│           ├── database/
│           │   └── rds/
│           │       └── terragrunt.hcl
│           ├── network/
│           │   └── vpc/
│           │       └── terragrunt.hcl
│           └── storage/
│               └── s3/
│                   └── terragrunt.hcl
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

```bash
export AWS_PROFILE=develop
export AWS_REGION=us-east-1
```

Ou use `~/.aws/credentials`:
```
[develop]
aws_access_key_id = YOUR_ACCESS_KEY
aws_secret_access_key = YOUR_SECRET_KEY
region = us-east-1
```

### 2. Crie o Bucket de Estado S3 (primeira vez apenas)

```bash
aws s3 mb s3://terragrunt-example-tf-state-develop-us-east-1 --region us-east-1
```

### 3. Configure o Banco de Dados para Locking (opcional)

```bash
aws dynamodb create-table \
    --table-name terraform-locks \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region us-east-1
```

## 📖 Como Usar

### Inicializar

```bash
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
