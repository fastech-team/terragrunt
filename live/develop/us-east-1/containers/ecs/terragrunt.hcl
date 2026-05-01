# Configuração do ECS (develop/resources/ecs/terragrunt.hcl) ###

# Inclui configuração raiz
include "root" {
  path = find_in_parent_folders("root-terragrunt.hcl")
}

# Inclui configuração do ambiente
include "environment" {
  path = find_in_parent_folders("environment.hcl")
}

terraform {
  source = "../../../modules/ecs"
}

inputs = {
  cluster_name = "mycluster"
  environment = include.environment.locals.environment
}