# Configuração do ECS (develop/resources/ecs/terragrunt.hcl) ###

# Inclui configuração raiz
include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "vpc" {
  config_path = "../../network/vpc"

  mock_outputs = {
    vpc_id = "vpc-0123456789abcdef0"
    public_subnets = [
      "subnet-01234567890123456",
      "subnet-01234567890123457",
      "subnet-01234567890123458"
    ]
    private_subnets = [
      "subnet-01234567890123459",
      "subnet-01234567890123460",
      "subnet-01234567890123461"
    ]
  }

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

locals {
  env_config = read_terragrunt_config(find_in_parent_folders("environment.hcl"))
}

terraform {
  source = "../../../../modules/ecs-fargate-cluster"
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
  vpc_id = dependency.vpc.outputs.vpc_id

  load_balancers = {
    external = {
      internal           = false
      load_balancer_type = "application"
      subnets            = dependency.vpc.outputs.public_subnets
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
    }

    internal = {
      internal           = true
      load_balancer_type = "application"
      subnets            = dependency.vpc.outputs.private_subnets
      ingress_rules = {
        http = {
          port         = 80
          protocol     = "TCP"
          allowed_cidr = "0.0.0.0/0"
        }
      }
    }
  }

  domain = "fastech.com"
}