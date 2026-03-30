### Configuração do Bucket 01 (dev/resources/s3-bucket01/terragrunt.hcl) ###

# Inclui configuração do ambiente dev
include "dev" {
  path = find_in_parent_folders("dev/terragrunt.hcl")
}

terraform {
  source = "../../../modules/s3"
}

inputs = {
  bucket_name = "mybucket01"
  environment = include.dev.locals.environment
  tags = merge(include.dev.inputs.tags, {
    Name        = "mybucket01"
    Description = "Bucket para dados de origem"
    Purpose     = "Data Lake - Raw Zone"
  })
}