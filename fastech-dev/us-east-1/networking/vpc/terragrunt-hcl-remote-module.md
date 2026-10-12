terraform {
  source = "tfr:///terraform-aws-modules/vpc/aws?version=6.6.1"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}
locals {
  env_config = read_terragrunt_config(find_in_parent_folders("environment.hcl"))
}

inputs = {
  name = "fastech"
  cidr = "10.33.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.33.0.0/20", "10.33.16.0/20", "10.33.32.0/20"]
  public_subnets  = ["10.33.64.0/20", "10.33.80.0/20", "10.33.96.0/20"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}
