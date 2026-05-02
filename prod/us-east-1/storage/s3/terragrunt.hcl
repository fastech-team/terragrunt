### Configuração do Bucket 01 (develop/resources/s3-bucket01/terragrunt.hcl) ###

# Inclui configuração raiz
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Inclui configuração do ambiente
include "environment" {
  path = find_in_parent_folders("environment.hcl")
}

terraform {
  source = "../../../modules/s3"
}

inputs = {
  bucket_name = "mybucket01"
  environment = include.environment.locals.environment
  tags = merge(include.environment.inputs.tags, {
    Name        = "mybucket01"
    Description = "Bucket para dados de origem"
    Purpose     = "Data Lake - Raw Zone"
  })
}