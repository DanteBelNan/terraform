provider "aws" {
  region = "us-east-2" 
}


module "github_repo" {
  source          = "../../../modules/github_repo"
  app_name        = var.app_name
  github_token    = var.github_token
  github_owner    = var.github_owner
  repo_template   = var.repo_template
}

# 1. Definición del ECR
module "ecr" {
  source   = "../../../modules/ecr"
  app_name = var.app_name 
}

# 2. Definición del Servidor (EC2, EIP, SG)
module "compute_server" {
  source          = "../../../modules/compute"
  app_name        = var.app_name
  instance_type   = var.instance_type
  github_repo_url = var.github_repo_url
  build_command   = var.build_command 
}