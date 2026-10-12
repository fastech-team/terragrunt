terraform {
  source = "../../../../modules/vpc"
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
    project_name = "fastech"
    vpc_cidr = "10.50.0.0/16"
    environment = local.environment.locals.environment
    availability_zones = local.region.locals.availability_zones
    private_subnet_cidrs = ["10.50.1.0/24", "10.50.2.0/24", "10.50.3.0/24"]
    public_subnet_cidrs = ["10.50.10.0/24", "10.50.11.0/24", "10.50.12.0/24"]
    enable_nat_gateway = true
    enable_dns_hostnames = true
    enable_dns_support = true
    tags = {
        CostCenter = "DevTeam"
        AutoOff    = "true"
        Project    = "Fastech"
        Awner     = "Devops team"
    }
}