# --- AWS Provider Configuration ---
provider "aws" {
  region = "us-east-2" 
}

# 1. ECR Definition Module
module "ecr" {
  source   = "../../modules/ecr"
  app_name = var.app_name 
  repo_names = ["node-repo", "nginx-repo", "cli-repo"] 
}

# 2. GitHub Module
module "github_repo" {
  source          = "../../modules/github_repo"
  app_name        = var.app_name
  
  # Repository Configuration Parameters
  github_token    = var.github_token
  github_owner    = var.github_owner
  repo_template   = var.repo_template
  
  # CI/CD Parameters
  ecr_repository_urls   = module.ecr.repository_urls 
  aws_access_key_id     = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key
}

# 3. Compute Server Definition (EC2, EIP, SG)
module "compute_server" {
  source          = "../../modules/compute"
  app_name        = var.app_name
  instance_type   = var.instance_type
  
  github_repo_url = module.github_repo.http_clone_url
  aws_region      = "us-east-2" 
  
  build_command   = var.build_command
}