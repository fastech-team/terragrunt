###  Configuração da EC2 Metabase (dev/resources/ec2-metabase/terragrunt.hcl) ###

# Inclui configuração do ambiente dev
include "dev" {
  path = find_in_parent_folders("dev/terragrunt.hcl")
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
  environment   = include.dev.locals.environment
  tags = merge(include.dev.inputs.tags, {
    Name        = "metabase-dev"
    Application = "Metabase"
    AutoOff     = "true"
  })
  subnet_id = dependency.network.outputs.subnet_id
}