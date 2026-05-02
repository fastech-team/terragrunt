# Configuração do RDS (develop/resources/rds/terragrunt.hcl) ###

# Inclui configuração raiz
include "root" {
  path = find_in_parent_folders("root-terragrunt.hcl")
}

# Inclui configuração do ambiente
include "environment" {
  path = find_in_parent_folders("environment.hcl")
}

terraform {
  source = "../../../modules/rds"
}

inputs = {
  db_name = "mydb"
  environment = include.environment.locals.environment
}