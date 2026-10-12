# ECS tasks

O módulo cria uma task e um serviço por entrada de `container_definitions`.

## Rede

O módulo usa Fargate com `network_mode = "awsvpc"` fixo e target groups do tipo
`ip`. O ECS usa a porta do container também como porta do host, sem necessidade
de informar `hostPort`. A configuração de rede é um bloco direto.
O serviço herda a estratégia de capacidade do cluster, preservando FARGATE_SPOT.
Informe `subnets_id`. As subnets precisam de saída para ECR, CloudWatch e Secrets Manager
por NAT ou VPC endpoints; as tasks não recebem IP público.
Todas as tasks deste módulo compartilham um security group com entrada TCP nas
portas 80 e 443 a partir dos security groups dos dois ALBs. A saída IPv4 é livre.
As aplicações e os target groups precisam usar essas portas; portas como 8080
e 9000 não são permitidas por essas regras.

Os target groups usam prefixos `ext-` e `int-` com sufixos gerados para permitir
substituição com `create_before_destroy`.

## Variáveis e secrets

`task_variables` recebe listas de `{ name, value }` por nome de task.
`global_secrets` mapeia as chaves da secret compartilhada, identificada por `global_secret_name`. Todas as tasks recebem essas variáveis além das próprias.
`task_secrets` recebe mapas de variável de ambiente para chave JSON por task.
O data source busca a secret existente pelo nome exato da task e monta o ARN com `:chave-json::`. O Terraform precisa de `secretsmanager:DescribeSecret` e `secretsmanager:GetResourcePolicy`; nenhuma leitura dos valores é feita por ele.

Use as mesmas chaves de `container_definitions`. Uma task ausente dos mapas
recebe uma lista vazia. Mantenha nomes de variáveis únicos entre configurações
globais, específicas e secrets: `concat` não sobrescreve entradas por nome.

Não coloque senhas em `task_variables`: `sensitive` oculta a saída usual, mas
os valores permanecem no state. O ECS resolve `task_secrets` ao iniciar a task.
A execution role deve poder ler os secrets e, quando usada uma chave KMS
gerenciada pelo cliente, descriptografar com essa chave.

Depois de alterar ou rotacionar um secret, dispare um novo deployment do serviço.
`force_new_deployment = true` não monitora alterações no Secrets Manager.
