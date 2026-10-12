
terraform {
  source = "../../../../modules/cloudfront"
}

# Inclui configuração raiz
include "root" {
  path = find_in_parent_folders("root.hcl")
}


locals {
  environment = read_terragrunt_config(find_in_parent_folders("environment.hcl"))
  account     = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region      = read_terragrunt_config(find_in_parent_folders("region.hcl"))
}

inputs = {
  site_name = "fastech"
  domain    = "fastech.com.br"
  # Usa o dominio personalizado e o certificado ACM.
  aws_acm_certificate = false
  cname     = "dev-visitors"
  environment = local.environment.locals.environment
  enable_waf = false
  region    = local.region.locals.aws_region
  additional_origins = [
    {
      origin_id   = "api-dev-visitors-apigw"
      domain_name = "api-dev-visitors.fastech.com.br"
    },
  ]

  # A ordem dos caminhos define a prioridade dos behaviors (0 a 11).
  additional_behaviors = [
    for path in [
      "/bff-prxy*",
      "/protected",
      "/auth/*",
      "/credential/*",
      "/certificate/*",
      "/guest-invite/*",
      "/group-management/*",
      "/reports/*",
      "/rprt*",
      "/exhibitor-portal/profile*",
      "/exhibitor-portal/exchange-token*",
      "/exhibitor-portal/invites*",
    ] : {
      path_pattern     = path
      target_origin_id = "api-dev-visitors-apigw"
    }
  ]

  tags = {
    # Our account factory sets the name of the VPC it vends to the name of the AWS account by default.
    Name = local.account_vars.locals.account_name
  }
}