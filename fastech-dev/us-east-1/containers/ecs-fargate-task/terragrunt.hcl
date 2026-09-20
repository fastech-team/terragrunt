terraform {
  source = "../../../../modules/ecs-fargate-task"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "vpc" {
  config_path = "../../network/vpc"

  mock_outputs = {
    vpc_id = "vpc-0123456789abcdef0"

    private_subnets = [
      "subnet-01234567890123456",
      "subnet-01234567890123457",
      "subnet-01234567890123458"
    ]
  }

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

locals {
  environment = read_terragrunt_config(find_in_parent_folders("environment.hcl"))
  account     = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region      = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  
  # variaveis de ambiente no formato nativo esperado pelo ECS
  env_global       = yamldecode(file("${get_terragrunt_dir()}/env-vars/env-var-global.yaml"))
  env_client_api   = yamldecode(file("${get_terragrunt_dir()}/env-vars/client-api.yaml"))
  env_client_worker = yamldecode(file("${get_terragrunt_dir()}/env-vars/client-worker.yaml"))

  secret_arn = "arn:aws:secretsmanager:${local.region.locals.aws_region}:${local.account.locals.aws_account_id}:secret"
  secret_config = yamldecode(file("${get_terragrunt_dir()}/secrets/secrets.yaml"))

  task_secrets = {
    for task_name, secret_names in local.secret_config.tasks : task_name => concat(
      [
        for secret_name in local.secret_config.global : {
          name      = secret_name
          valueFrom = "${local.secret_arn}:fastech/${local.environment.locals.environment}/global:${secret_name}::"
        }
      ],
      [
        for secret_name in secret_names : {
          name      = secret_name
          valueFrom = "${local.secret_arn}:fastech/${local.environment.locals.environment}/${task_name}:${secret_name}::"
        }
      ]
    )
  }

}


inputs = {
  image_tag = "latest"
  cluster_name = "fastech"
  aws_region = local.region.locals.aws_region
  account_id = local.account.locals.aws_account_id
  environment = local.environment.locals.environment
  domain = "fastech.com"
  registry = "fastech"
  load_balancer = "alb-fastech-external"
  internal_load_balancer = "alb-fastech-internal"
  log_retention_days = "14"
  subnets_id = dependency.vpc.outputs.private_subnets
  vpc_id = dependency.vpc.outputs.vpc_id
  container_definitions = {
    client-api = {
      container_port     = 8080
      cpu                = 256
      memory             = 512
      desired_count      = 2
      min_tasks          = 1
      max_tasks          = 3
      cpu_target_scaling = 70
      mem_target_scaling = 70
      health_path        = "helth"
    }
    client-worker = {
      container_port     = 9000
      cpu                = 256
      memory             = 512
      desired_count      = 1
      min_tasks          = 1
      max_tasks          = 3
      cpu_target_scaling = 70
      mem_target_scaling = 70
      health_path        = "helth"
    }
  }
  task_variables = {
    client-api    = concat(local.env_global, local.env_client_api)
    client-worker = concat(local.env_global, local.env_client_worker)
  }

  task_secrets = local.task_secrets

}