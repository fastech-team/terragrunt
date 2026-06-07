### Configuração do Ambiente Dev (dev/terragrunt.hcl) ###

# Configurações específicas do ambiente dev
locals {
  environment = "prod"
}

# Inputs que serão passados para todos os recursos do dev
inputs = {
  environment = local.environment
  
  # Tags específicas do dev
  tags = {
    Environment = local.environment
    CostCenter  = "DevTeam"
    AutoOff     = "true"  # Para identificar recursos que podem ser desligados
  }
}