# GUIA: Escalando para Produção

Este documento descreve como estruturar e escalar o projeto para ambientes de produção.

## 1. Estrutura de Ambientes

### Desenvolvimento
- AWS Account ID: 111111111111
- Localização: `live/develop/`
- Características:
  - t3.micro/t3.small para compute
  - 7 dias de retenção de backups
  - Sem Multi-AZ
  - AutoOff habilitado
  - Container Insights desabilitado

### Staging
- AWS Account ID: 222222222222
- Localização: `live/staging/`
- Características:
  - t3.small/t3.medium para compute
  - 14 dias de retenção de backups
  - Multi-AZ em RDS
  - Container Insights desabilitado
  - Testes de scaling

### Produção
- AWS Account ID: 333333333333
- Localização: `live/prod/`
- Características:
  - t3.medium/t3.large para compute
  - 30 dias de retenção de backups
  - Multi-AZ em tudo
  - Container Insights habilitado
  - Deletion protection ativo
  - High availability

## 2. Estrutura de Diretórios

```
live/
├── prod/
│   ├── account.hcl
│   │   account_name   = "production"
│   │   aws_account_id = "333333333333"
│   │   aws_profile    = "prod"
│   ├── environment.hcl
│   │   environment = "prod"
│   │   multi_az    = true
│   │   backup_retention = 30
│   └── us-east-1/
│       ├── region.hcl
│       ├── compute/
│       ├── containers/
│       ├── database/
│       ├── network/
│       └── storage/
├── staging/
│   └── ...
└── develop/
    └── ...
```

## 3. Arquivo account.hcl para Produção

```hcl
locals {
  account_name   = "production"
  aws_account_id = "333333333333"
  aws_profile    = "prod"
}
```

## 4. Arquivo environment.hcl para Produção

```hcl
include "root" {
  path = find_in_parent_folders("root-terragrunt.hcl")
}

locals {
  environment = "prod"
}

inputs = {
  environment = local.environment
  
  # Sempre ativar em produção
  multi_az                    = true
  enable_container_insights   = true
  deletion_protection         = true
  
  # Retenção aumentada
  backup_retention_period     = 30
  log_group_retention_days    = 30
  
  tags = {
    Environment = "production"
    CostCenter  = "Operations"
    Compliance  = "required"
    AutoOff     = "false"
    BackupDaily = "true"
  }
}
```

## 5. Exemplo: EC2 em Produção

```hcl
# live/prod/us-east-1/compute/web-server/terragrunt.hcl

include "root" {
  path = find_in_parent_folders("root-terragrunt.hcl")
}

include "environment" {
  path = find_in_parent_folders("environment.hcl")
}

dependency "vpc" {
  config_path = "../../network/vpc"
}

dependency "security_group" {
  config_path = "../../network/security-group-web"
}

terraform {
  source = "../../../modules/ec2"
}

inputs = {
  instance_name           = "web-server-prod-01"
  instance_type           = "t3.large"  # Maior que dev
  subnet_id               = dependency.vpc.outputs.private_subnets[0]
  vpc_security_group_ids  = [dependency.security_group.outputs.id]
  environment             = include.environment.locals.environment
  
  associate_public_ip     = false  # Sempre false em prod
  root_volume_size        = 50
  root_volume_type        = "gp3"
  
  tags = merge(
    include.environment.inputs.tags,
    {
      Name        = "web-server-prod-01"
      Application = "WebApp"
      Tier        = "Frontend"
    }
  )
}
```

## 6. Exemplo: RDS em Produção

```hcl
# live/prod/us-east-1/database/postgres/terragrunt.hcl

include "root" {
  path = find_in_parent_folders("root-terragrunt.hcl")
}

include "environment" {
  path = find_in_parent_folders("environment.hcl")
}

dependency "vpc" {
  config_path = "../../network/vpc"
}

dependency "security_group" {
  config_path = "../../network/security-group-db"
}

terraform {
  source = "../../../modules/rds"
}

inputs = {
  db_identifier               = "mydb-prod"
  db_name                     = "production_db"
  engine                      = "postgres"
  engine_version              = "14"
  instance_class              = "db.t3.medium"  # Maior que dev
  allocated_storage           = 100
  max_allocated_storage       = 500
  
  environment                 = include.environment.locals.environment
  multi_az                    = true  # CRÍTICO
  publicly_accessible         = false  # CRÍTICO
  backup_retention_period     = 30
  backup_window               = "03:00-04:00"
  maintenance_window          = "sun:04:00-sun:05:00"
  
  enable_cloudwatch_logs_exports = ["postgresql"]
  skip_final_snapshot         = false
  
  vpc_security_group_ids      = [dependency.security_group.outputs.id]
  db_subnet_group_name        = dependency.vpc.outputs.db_subnet_group_name
  
  tags = merge(
    include.environment.inputs.tags,
    {
      Name        = "mydb-prod"
      Database    = "PostgreSQL"
      Tier        = "Data"
    }
  )
}
```

## 7. Políticas de Segurança

### Firewall
```hcl
# Security Groups devem restringir ao máximo
resource "aws_security_group" "web" {
  name = "web-prod"
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

### Secrets Management
```bash
# Use AWS Secrets Manager em vez de tfvars
aws secretsmanager create-secret \
    --name prod/db/password \
    --secret-string "$(openssl rand -base64 32)"

# No Terraform
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "prod/db/password"
}

# Referencia no RDS
password = data.aws_secretsmanager_secret_version.db_password.secret_string
```

## 8. Monitoramento e Alertas

### CloudWatch
```hcl
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "prod-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_actions       = [aws_sns_topic.alerts.arn]
}
```

### CloudTrail
```hcl
resource "aws_cloudtrail" "main" {
  name                          = "prod-audit-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  include_global_service_events = true
  is_multi_region_trail         = true
  depends_on                    = [aws_s3_bucket_policy.cloudtrail]
}
```

## 9. Backup e Disaster Recovery

### Estratégia
- RDS: 30 dias de retenção, backup automático diário
- S3: Versionamento + ciclo de vida
- EC2: AMI snapshots semanais

### Teste de Recuperação
```bash
# Teste de restore de RDS
aws rds restore-db-instance-from-db-snapshot \
    --db-instance-identifier mydb-prod-restore-test \
    --db-snapshot-identifier mydb-prod-snapshot-2024-05-01
```

## 10. Cost Optimization

### Recomendações
- Use Reserved Instances para baseline
- Use Spot Instances para workloads flexíveis
- Ativar autoscaling em ECS
- Configurar lifecycle policies em S3
- Usar S3 Intelligent-Tiering

## 11. Checklist de Deploy para Produção

- [ ] Account ID correto em account.hcl
- [ ] Multi-AZ ativado
- [ ] Deletion protection ativado
- [ ] Backups configurados (30 dias)
- [ ] CloudWatch logs habilitado
- [ ] Alarms criados
- [ ] Security groups restritivos
- [ ] Não há IPs públicos abertos
- [ ] Senha salva em Secrets Manager
- [ ] Teste de restore executado
- [ ] Documentação atualizada
- [ ] Aprovação de segurança obtida

## 12. Processo de Deploy

### Fase 1: Preparação
```bash
# 1. Atualizar código
git pull origin main

# 2. Validar
cd live/prod
terragrunt validate-all

# 3. Planejar
terragrunt plan-all > plan.txt
# Revisar plan.txt
```

### Fase 2: Deploy
```bash
# 1. Criar snapshot (backup)
aws rds create-db-snapshot --db-instance-identifier mydb-prod

# 2. Aplicar com cuidado
cd live/prod/us-east-1/network/vpc
terragrunt apply  # Aplicar primeiro a VPC

# 3. Depois ECS, RDS, etc
terragrunt apply-all
```

### Fase 3: Validação
```bash
# 1. Testar conectividade
terraform output vpc_id
aws ec2 describe-instances

# 2. Validar aplicação
curl https://your-app.com/health

# 3. Monitorar logs
aws logs tail /ecs/your-cluster --follow
```

## 13. Rollback

```bash
# Se algo der errado
cd live/prod
terragrunt refresh          # Atualizar state
terragrunt show            # Ver estado atual
terraform rollback         # Se aplicável

# Ou destruir e recriar
terragrunt destroy-all
terragrunt apply-all
```

## Recursos Adicionais

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Terraform AWS Best Practices](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terragrunt Documentation](https://terragrunt.gruntwork.io/)
