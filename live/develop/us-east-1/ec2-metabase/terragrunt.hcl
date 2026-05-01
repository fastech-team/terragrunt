###  Configuração da EC2 Metabase (develop/resources/ec2-metabase/terragrunt.hcl) ###

# Inclui configuração do ambiente develop
include "develop" {
  path = find_in_parent_folders("develop/terragrunt.hcl")
}

terraform {
  source = "../../../modules/ec2"
}

dependency "network" {
  config_path = "../network"
}

inputs = {
  instance_name = "metabase-dev"
  instance_type = "t3.medium"
  environment   = include.develop.locals.environment
  tags = merge(include.develop.inputs.tags, {
    Name        = "metabase-dev"
    Application = "Metabase"
    AutoOff     = "true"
  })
  subnet_id = dependency.network.outputs.subnet_id
}