# ECS task secrets

O arquivo `secrets.yaml` lista as chaves JSON que serão extraídas pelo ECS.
Ele não deve conter os valores dos secrets.

Crie os secrets no AWS Secrets Manager com estes nomes:

- `fastech/dev/global`
- `fastech/dev/client-api`
- `fastech/dev/client-worker`

Exemplo de conteúdo para o secret global:

```json
{
  "DB_HOST": "database.example.internal",
  "DB_USERNAME": "app_user",
  "DB_PASSWORD": "replace-me"
}
```

Exemplo de criação via AWS CLI:

```bash
aws secretsmanager create-secret \
  --name fastech/dev/global \
  --secret-string '{"DB_HOST":"database.example.internal","DB_USERNAME":"app_user","DB_PASSWORD":"replace-me"}'
```

O `global` é injetado em todas as tasks. A seção `tasks` contém os secrets
específicos de cada task. O ECS usa `secrets[].valueFrom` com o formato
`ARN:json-key::` e injeta cada chave como uma variável de ambiente dentro do
container.