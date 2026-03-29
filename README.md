# terragrunt
Demo terragrunt project

meu-projeto/
├── terragrunt.hcl                    # Configuração raiz
├── dev/                               # Ambiente de desenvolvimento
│   ├── terragrunt.hcl                # Configuração específica do dev
│   └── resources/
│       ├── s3-bucket01/
│       │   └── terragrunt.hcl
│       ├── s3-bucket02/
│       │   └── terragrunt.hcl
│       └── ec2-metabase/
│           └── terragrunt.hcl
└── modules/                           # Módulos Terraform reutilizáveis
    ├── s3-bucket/
    │   └── main.tf
    └── ec2-instance/
        └── main.tf



## Como Executar

## 1. Configure suas credenciais AWS:
bash
export AWS_ACCESS_KEY_ID="sua-chave"
export AWS_SECRET_ACCESS_KEY="seu-segredo"
export AWS_DEFAULT_REGION="us-east-1"

## 2. Crie o bucket de estado (primeira vez apenas):
bash
aws s3 mb s3://meu-projeto-terraform-state --region us-east-1
aws dynamodb create-table \
    --table-name terraform-locks \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region us-east-1

## 3. Execute para criar todos os recursos:
bash
# Navegue até o diretório do ambiente dev
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

## 4. Comandos úteis:
bash
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