# Configuração do ECS (develop/resources/ecs/terragrunt.hcl) ###

# Inclui configuração raiz
include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "vpc" {
  config_path = "../../network/vpc"
}

locals {
  env_config = read_terragrunt_config(find_in_parent_folders("environment.hcl"))
}

terraform {
  source = "../../../../modules/ecs-fargate"
}

inputs = {
  cluster_name = "fastech"
  enable_container_insights = "enhanced"
  environment = local.env_config.locals.environment
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]
  capacity_provider_strategy = {
    capacity_provider = "FARGATE"
    weight            = 100
    base              = 1
  }
  log_group_retention_days = 7
  tags = local.env_config.inputs.tags
  load_balancers = {
    external = {
      internal        = false
      subnets         = dependency.vpc.outputs.public_subnets
      ingress_rules = {
        http = {
          port         = 80
          protocol     = "TCP"
          allowed_cidr = "0.0.0.0/0"
        }
        https = {
          port         = 443
          protocol     = "TCP"
          allowed_cidr = "0.0.0.0/0"
        }
      }

    internal = {
      internal        = true
      subnets         = dependency.vpc.outputs.private_subnets
      ingress_rules = {
        http = {
          port         = 80
          protocol     = "TCP"
          allowed_cidr = "0.0.0.0/0"
        }
      }
    }
  }
  domain = local.env_config.inputs.domain # Substitua pelo ID real do security group   
}