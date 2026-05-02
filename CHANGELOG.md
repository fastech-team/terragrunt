# Changelog

Histórico de mudanças do projeto de infraestrutura.

## [1.1.0] - 2024-05-02

### Mudanças Estruturais
- **Migração para padrão infrastructure-live**: Removida pasta `live/` separada
- **Estrutura plana**: Ambientes `develop/` e `prod/` diretamente na raiz
- **Arquivo raiz**: Renomeado `root-terragrunt.hcl` → `root.hcl`
- **Referências corrigidas**: Todos os `terragrunt.hcl` atualizados para usar `root.hcl`

### Corrigido
- Referências quebradas em todos os arquivos terragrunt.hcl (develop e prod)
- Paths de include atualizados para nova estrutura
- Dependências mantidas funcionais

### Documentação
- **README.md**: Estrutura atualizada para refletir mudanças
- **QUICK_REFERENCE.md**: Mapa visual atualizado
- **SUMMARY.md**: Resumo das mudanças estruturais

## [1.0.0] - 2024-05-01

### Adicionado
- Estrutura base de Terragrunt e Terraform
- Módulo EC2 com suporte a múltiplas instâncias
- Módulo VPC completo com subnets públicas e privadas
- Módulo S3 com segurança e versionamento
- Módulo ECS com suporte a Fargate e Fargate Spot
- Módulo RDS com suporte a múltiplos engines
- Configurações raiz e de ambiente
- Documentação completa em README.md
- Guia de boas práticas

### Corrigido
- Typo em account.hcl (develp → develop)
- Include quebrado em terragrunt.hcl (referência a arquivo inexistente)
- Dependency name mismatch em EC2 (vpc vs network)
- Inconsistência em referência de include (develop vs environment)

### Segurança
- Criptografia habilitada em S3 por padrão
- Criptografia de volume em EC2
- Block Public Access em S3
- IAM roles com princípio do menor privilégio
- Deletion protection em produção

## [0.1.0] - Inicial

Estrutura inicial com erros de referência.
