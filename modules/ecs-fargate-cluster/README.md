# Módulo ECS

Módulo Terraform para criar um cluster ECS (Elastic Container Service) na AWS com boas práticas, logs e IAM roles.

## Recursos Criados

- Cluster ECS
- Capacity Providers (FARGATE, FARGATE_SPOT)
- CloudWatch Log Group
- Container Insights (opcional)
- IAM Task Execution Role
- IAM Task Role

## Variáveis

- `cluster_name` - Nome do cluster (obrigatório)
- `environment` - Ambiente: dev, staging, prod (obrigatório)
- `capacity_providers` - Capacity providers (padrão: [FARGATE, FARGATE_SPOT])
- `default_capacity_provider_strategy` - Estratégia padrão (padrão: FARGATE)
- `enable_container_insights` - Habilitar Container Insights (padrão: false)
- `log_group_retention_days` - Dias de retenção de logs (padrão: 7)
- `tags` - Tags adicionais (padrão: {})

## Outputs

- `cluster_id` - ID do cluster
- `cluster_name` - Nome do cluster
- `cluster_arn` - ARN do cluster
- `log_group_name` - Nome do Log Group
- `log_group_arn` - ARN do Log Group
- `ecs_task_execution_role_arn` - ARN da task execution role
- `ecs_task_role_arn` - ARN da task role
- `capacity_providers` - Capacity providers configurados
