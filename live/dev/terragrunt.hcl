### Configuração do Ambiente Dev (dev/terragrunt.hcl) ###

# Inclui configurações raiz
include "root" {
  path = find_in_parent_folders()
}

# Configurações específicas do ambiente dev
locals {
  environment = "dev"
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