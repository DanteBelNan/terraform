# operations/create_instance/main.tf

# --- AWS Provider Configuration ---
provider "aws" {
  region = "us-east-2"
}

# --- GitHub Provider Configuration ---
provider "github" {
  token = var.github_token
  owner = var.github_owner
}

# 1. ECR Definition Module
module "ecr" {
  source   = "../../modules/ecr"
  app_name = var.app_name 
  repo_names = ["node-repo", "nginx-repo", "cli-repo"] 
}

# 2. GitHub Repository Module
module "github_repo" {
  source          = "../../modules/github_repo"
  app_name        = var.app_name
  
  # Repository Configuration Parameters
  github_token    = var.github_token
  github_owner    = var.github_owner
  repo_template   = var.repo_template
  
  # CI/CD Parameters
  ecr_repository_urls   = module.ecr.ecr_repository_urls
  aws_access_key_id     = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key
  app_instance_id       = module.compute_server.instance_id 
}

# 3. Compute Server Definition (Application Server)
module "compute_server" {
  source          = "../../modules/compute"
  app_name        = var.app_name
  instance_type   = var.instance_type
  aws_region      = "us-east-2"
}

# ----------------------------------------------------
# OUTPUTS 
# ----------------------------------------------------

output "app_instance_id" {
  description = "Application server instance ID."
  value       = module.compute_server.instance_id
}

output "app_public_ip" {
  description = "Public IP address."
  value       = module.compute_server.instance_ip
}

output "github_repository_url" {
  description = "URL of the created repository."
  value       = module.github_repo.http_clone_url
}