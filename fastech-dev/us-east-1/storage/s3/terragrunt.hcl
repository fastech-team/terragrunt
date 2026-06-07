### Configuração do Bucket 01 (develop/resources/s3-bucket01/terragrunt.hcl) ###

# Inclui configuração raiz
include "root" {
  path = find_in_parent_folders("root.hcl")
}
locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  env_config = read_terragrunt_config(find_in_parent_folders("environment.hcl"))
}

terraform {
  source = "../../../../modules/s3"
}

inputs = {
  bucket_name = "mybucket01-fastech-dev"
  environment = local.env_config.locals.environment
  tags = merge(local.env_config.inputs.tags, {
    Name        = "mybucket01"
    Description = "Bucket para dados de origem"
    Purpose     = "Data Lake - Raw Zone"
  })
}