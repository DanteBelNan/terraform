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

# --- Jenkins Provider Configuration ---
provider "jenkins" {
  server_url = "http://13.58.18.54:8080/" #Hardocding ip of my jenkins, bad practice but i can make it better next time :p
  username   = var.jenkins_admin_user
  password   = var.jenkins_admin_token # This should be an API Token, not a password
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
  ecr_repository_urls   = module.ecr.repository_urls
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

data "jenkins_script" "github_credential_validator" {
  name = "validate_github_pat"
  script = templatefile("${path.module}/templates/validate_credential.groovy.tpl", {
    credential_id = "GITHUB_PAT_ID"
  })
}

resource "jenkins_job" "app_pipeline" {
  name     = "${var.app_name}-pipeline"
  template = templatefile("${path.module}/templates/job_template.xml.tpl", {
    app_name      = var.app_name
    repo_url      = module.github_repo.http_clone_url 
    
    credential_id = data.jenkins_credential_secret_text.github_pat.name 
    
    branch_name   = "*/main"
  })

  # We no longer need depends_on because we are not creating the credential
  # depends_on = [jenkins_credential_secret_text.github_pat] # You can remove this line
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