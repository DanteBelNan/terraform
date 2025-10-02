# --- AWS Provider Configuration ---
provider "aws" {
  region = "us-east-2" 
}

# 1. ECR Definition Module
module "ecr" {
  source   = "../../modules/ecr"
  app_name = var.app_name 
}

# 2. GitHub Module (Creates Repo, Secrets, and Workflow)
module "github_repo" {
  source          = "../../modules/github_repo"
  app_name        = var.app_name
  
  # Repository Configuration Parameters
  github_token    = var.github_token
  github_owner    = var.github_owner
  repo_template   = var.repo_template
  
  # CI/CD Parameters (GitHub Actions Secrets & Workflow)
  ecr_repository_url    = module.ecr.repository_url 
  aws_access_key_id     = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key
}

# 3. Compute Server Definition (EC2, EIP, SG)
module "compute_server" {
  source          = "../../modules/compute"
  app_name        = var.app_name
  instance_type   = var.instance_type
  
  # Pass ECR URI, Region, and Run Command
  ecr_image_uri   = "${module.ecr.repository_url}:latest"
  aws_region      = "us-east-2" 
  run_command     = var.run_command 
}