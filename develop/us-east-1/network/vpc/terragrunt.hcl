# Inclui configuração raiz
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Inclui configuração do ambiente
include "environment" {
  path = find_in_parent_folders("environment.hcl")
}

terraform {
  source = "../../../modules/vpc"
}