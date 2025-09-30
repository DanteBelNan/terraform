# operations/create_instance/main.tf

# --- Configuración del Proveedor AWS ---
provider "aws" {
  region = "us-east-2" 
}

# --- Configuración del Proveedor GitHub ---
# Obtiene el token de la variable de entorno TF_VAR_github_token
provider "github" {
  token = var.github_token
}

# 1. Definición del ECR
module "ecr" {
  source   = "../../../modules/ecr"
  app_name = var.app_name 
}

# 2. Módulo GitHub (Crea Repo, Secrets y Workflow)
module "github_repo" {
  source          = "../../../modules/github_repo"
  app_name        = var.app_name
  
  # Parámetros de Configuración del Repositorio
  github_token    = var.github_token
  github_owner    = var.github_owner
  repo_template   = var.repo_template
  
  # Parámetros para el CI/CD (GitHub Actions)
  ecr_repository_url = module.ecr.repository_url # <--- ECR URI CREADO POR EL MÓDULO ECR
  aws_access_key_id  = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key
  # aws_region (usará el default "us-east-2" en el módulo github_repo)
}

# 3. Definición del Servidor (EC2, EIP, SG)
module "compute_server" {
  source          = "../../../modules/compute"
  app_name        = var.app_name
  instance_type   = var.instance_type
  github_repo_url = module.github_repo.http_clone_url
  build_command   = var.build_command 
}