### Configuração do Ambiente Dev (dev/terragrunt.hcl) ###

# Inclui configurações raiz
include "root" {
  path = find_in_parent_folders()
}

# Configurações específicas do ambiente dev
locals {
  environment = "dev"
  # Nome único para evitar conflitos
  unique_id = "dev-${get_env("USER", "local")}"
}

# Inputs que serão passados para todos os recursos do dev
inputs = {
  environment = local.environment
  unique_id   = local.unique_id
  
  # Tags específicas do dev
  tags = {
    Environment = local.environment
    CostCenter  = "DevTeam"
    AutoOff     = "true"  # Para identificar recursos que podem ser desligados
  }
}