# Inclui configuração raiz
include "root" {
  path = find_in_parent_folders("root.hcl")
}
locals {
  env_config = read_terragrunt_config(find_in_parent_folders("environment.hcl"))
}

terraform {
  source = "../../../modules/vpc"
}