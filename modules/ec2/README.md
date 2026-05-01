# Módulo EC2

Módulo Terraform para criar instâncias EC2 na AWS com boas práticas de segurança e configuração.

## Recursos Criados

- Instância EC2 com AMI Ubuntu mais recente
- Volume raiz criptografado
- Monitoramento habilitado para ambiente de produção
- EBS otimizado em produção

## Variáveis

- `instance_name` - Nome da instância (obrigatório)
- `instance_type` - Tipo de instância (padrão: t3.micro)
- `subnet_id` - ID da subnet (obrigatório)
- `environment` - Ambiente: dev, staging, prod (obrigatório)
- `tags` - Tags adicionais (padrão: {})
- `associate_public_ip` - Associar IP público (padrão: false)
- `root_volume_size` - Tamanho do volume em GB (padrão: 20)
- `root_volume_type` - Tipo de volume (padrão: gp3)
- `vpc_security_group_ids` - Security groups (padrão: [])

## Outputs

- `instance_id` - ID da instância
- `instance_arn` - ARN da instância
- `private_ip` - IP privado
- `public_ip` - IP público
- `primary_network_interface_id` - Network interface ID
- `instance_state` - Estado da instância
