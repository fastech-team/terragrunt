### Configuração Raiz (terragrunt.hcl) ###

# Configurações globais para todos os ambientes
locals {
  # Configurações comuns
  aws_region = "us-east-1"
  
  # Tags comuns para todos os recursos
  common_tags = {
    Project     = "MeuProjeto"
    ManagedBy   = "Terragrunt"
    Owner       = "Meu-Time"
  }
}

# Configuração do backend remoto para estado do Terraform
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "meu-projeto-terraform-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.aws_region
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

# Configurações que serão herdadas
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"
  default_tags {
    tags = {
      Environment = "${local.environment}"
    }
  }
}
EOF
}