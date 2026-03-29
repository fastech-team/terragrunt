# Inclui configuração do ambiente dev
include "dev" {
  path = find_in_parent_folders("dev/terragrunt.hcl")
}

terraform {
  source = "../../../modules/s3-bucket"
}

inputs = {
  bucket_name = "mybucket02-${include.dev.locals.unique_id}"
  environment = include.dev.locals.environment
  tags = merge(include.dev.inputs.tags, {
    Name        = "mybucket02"
    Description = "Bucket para dados processados"
    Purpose     = "Data Lake - Processed Zone"
  })
}