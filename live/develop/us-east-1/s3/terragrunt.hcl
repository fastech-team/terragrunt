### Configuração do Bucket 01 (develop/resources/s3-bucket01/terragrunt.hcl) ###

# Inclui configuração do ambiente develop
include "develop" {
  path = find_in_parent_folders("develop/terragrunt.hcl")
}

terraform {
  source = "../../../modules/s3"
}

inputs = {
  bucket_name = "mybucket01"
  environment = include.develop.locals.environment
  tags = merge(include.develop.inputs.tags, {
    Name        = "mybucket01"
    Description = "Bucket para dados de origem"
    Purpose     = "Data Lake - Raw Zone"
  })
}