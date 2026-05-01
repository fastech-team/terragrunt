# Módulo S3

Módulo Terraform para criar buckets S3 na AWS com boas práticas de segurança, versionamento e criptografia.

## Recursos Criados

- Bucket S3 privado
- Versionamento habilitado
- Criptografia no lado do servidor (SSE-S3 ou SSE-KMS)
- Block Public Access configurado
- ACL privado
- Logging de acesso (opcional)
- Regras de ciclo de vida (opcional)

## Variáveis

- `bucket_name` - Nome do bucket (obrigatório, deve ser único globalmente)
- `environment` - Ambiente: dev, staging, prod (obrigatório)
- `versioning_enabled` - Habilitar versionamento (padrão: true)
- `block_public_acls` - Bloquear ACLs públicas (padrão: true)
- `block_public_policy` - Bloquear política pública (padrão: true)
- `ignore_public_acls` - Ignorar ACLs públicas (padrão: true)
- `restrict_public_buckets` - Restringir buckets públicos (padrão: true)
- `enable_server_side_encryption` - Habilitar criptografia (padrão: true)
- `encryption_algorithm` - Algoritmo: AES256 ou aws:kms (padrão: AES256)
- `enable_logging` - Habilitar logging (padrão: false)
- `lifecycle_rules` - Regras de ciclo de vida (padrão: [])
- `tags` - Tags adicionais (padrão: {})

## Outputs

- `bucket_id` - Nome do bucket
- `bucket_arn` - ARN do bucket
- `bucket_region` - Região do bucket
- `bucket_domain_name` - Domain name do bucket
- `versioning_enabled` - Status do versionamento
- `encryption_enabled` - Status da criptografia
- `logs_bucket_id` - Nome do bucket de logs
