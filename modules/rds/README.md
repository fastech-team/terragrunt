# Módulo RDS

Módulo Terraform para criar uma instância RDS (Relational Database Service) na AWS com boas práticas de segurança, backups e monitoramento.

## Recursos Criados

- Instância RDS com múltiplos engines (MySQL, PostgreSQL, MariaDB, Oracle, SQL Server)
- Criptografia de armazenamento habilitada
- Parameter Group
- Option Group
- CloudWatch Alarms para monitoramento
- Multi-AZ (opcional)
- Backups automáticos
- Logs no CloudWatch (opcional)

## Variáveis

- `db_identifier` - Identificador do banco (obrigatório)
- `db_name` - Nome do banco (obrigatório)
- `engine` - Engine: mysql, postgres, mariadb, oracle-se2, sqlserver-se (obrigatório)
- `engine_version` - Versão do engine (padrão: 14)
- `instance_class` - Classe da instância (padrão: db.t3.micro)
- `allocated_storage` - Armazenamento em GB (padrão: 20)
- `max_allocated_storage` - Armazenamento máximo (padrão: 100)
- `username` - Usuário mestre (obrigatório, sensível)
- `password` - Senha (obrigatório, sensível)
- `environment` - Ambiente: dev, staging, prod (obrigatório)
- `multi_az` - Habilitar Multi-AZ (padrão: false)
- `publicly_accessible` - Acessível publicamente (padrão: false)
- `backup_retention_period` - Dias de retenção (padrão: 7)
- `backup_window` - Janela de backup (padrão: 03:00-04:00)
- `maintenance_window` - Janela de manutenção (padrão: mon:04:00-mon:05:00)
- `enable_cloudwatch_logs_exports` - Logs no CloudWatch (padrão: [])
- `skip_final_snapshot` - Pular snapshot final (padrão: false)
- `tags` - Tags adicionais (padrão: {})

## Outputs

- `db_instance_id` - ID da instância
- `db_instance_arn` - ARN da instância
- `db_instance_endpoint` - Endpoint de conexão
- `db_instance_address` - Endereço do banco
- `db_instance_port` - Porta de conexão
- `db_name` - Nome do banco
- `db_username` - Usuário mestre
- `db_engine` - Engine utilizado
- `db_engine_version` - Versão do engine
- `multi_az` - Status Multi-AZ
