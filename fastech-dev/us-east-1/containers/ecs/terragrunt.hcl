# Configuração do ECS (develop/resources/ecs/terragrunt.hcl) ###

# Inclui configuração raiz
include "root" {
  path = find_in_parent_folders("root.hcl")
}
locals {
  env_config = read_terragrunt_config(find_in_parent_folders("environment.hcl"))
}

terraform {
  source = "../../../modules/ecs"
}

inputs = {
  cluster_name = "mycluster"
  environment = local.env_config.locals.environment
}