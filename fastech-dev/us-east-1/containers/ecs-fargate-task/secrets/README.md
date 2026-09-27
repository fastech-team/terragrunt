# ECS task secrets

Cada task recebe chaves de duas secrets existentes no Secrets Manager:

- A global, compartilhada: `fastech/dev/global`, definida por `global_secret_name`.
- A própria task: `client-api` ou `client-worker`, com o nome exato da task.

Ambas são consultadas pelo nome usando `data.aws_secretsmanager_secret`.
O Terraform obtém apenas os ARNs; o ECS busca os valores ao iniciar o container.
Não é necessário definir variáveis `ECS_SECRET_ARN_*` nem copiar chaves globais
para as secrets individuais.

O arquivo `secrets.yaml` contém mapas de variável de ambiente para chave JSON:

```yaml
global:
  SHARED_TOKEN: TOKEN
tasks:
  client-api:
    API_DEV: API_KEY
```

Todas as tasks recebem SHARED_TOKEN da secret global. A task client-api também
recebe API_DEV da chave API_KEY de sua própria secret. Cada referência usa
`ARN:chave::`. Não repita nomes de variáveis entre global, task e variáveis comuns:
`concat` junta as listas, sem sobrescrever entradas por nome.

As secrets precisam existir antes do plan. Maiúsculas e minúsculas importam.
A identidade do Terraform precisa de `secretsmanager:DescribeSecret` e `secretsmanager:GetResourcePolicy` para ambas.
A execution role do ECS precisa de `secretsmanager:GetSecretValue` e, para uma
chave KMS do cliente, `kms:Decrypt` autorizado nessa chave.

O ECS usa AWSCURRENT. Após alterar ou rotacionar valores, faça um novo deployment.
Uma nova versão não altera o ARN; recriar a secret pode alterá-lo, e a próxima
atualização pelo Terraform resolve o novo ARN pelo nome.
