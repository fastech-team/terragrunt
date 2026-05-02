###  Configuração da EC2 Metabase (develop/resources/ec2-metabase/terragrunt.hcl) ###

# Inclui configuração raiz
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Inclui configuração do ambiente
include "environment" {
  path = find_in_parent_folders("environment.hcl")
}

terraform {
  source = "../../../modules/ec2"
}

dependency "vpc" {
  config_path = "../../network/vpc"
}

inputs = {
  instance_name = "metabase-dev"
  instance_type = "t3.medium"
  environment   = include.environment.locals.environment
  tags = merge(include.environment.inputs.tags, {
    Name        = "metabase-dev"
    Application = "Metabase"
    AutoOff     = "true"
  })
  subnet_id = dependency.vpc.outputs.subnet_id
}