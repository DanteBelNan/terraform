# modules/github_repo/main.tf

# --- Configuración del Proveedor GitHub ---
# Configuramos el proveedor con el token y el owner.
provider "github" {
  token = var.github_token
  owner = var.github_owner 
}

# --- 1. Creación del Repositorio a partir de Plantilla ---
resource "github_repository" "new_app_repo" {
  name        = lower(var.app_name) # Ej: chatappdev
  description = "Repositorio de la aplicación desplegada por Terraform."
  visibility  = "public"
  
  template {
    owner      = split("/", var.repo_template)[0]
    repository = split("/", var.repo_template)[1]
  }

  has_issues   = true
  has_projects = true
}

# --- 2. Inyección de Secrets de GitHub Actions (AWS Credentials) ---
resource "github_actions_secret" "aws_key_id" {
  repository      = github_repository.new_app_repo.name
  secret_name     = "AWS_ACCESS_KEY_ID"
  plaintext_value = var.aws_access_key_id
}

resource "github_actions_secret" "aws_secret_key" {
  repository      = github_repository.new_app_repo.name
  secret_name     = "AWS_SECRET_ACCESS_KEY"
  plaintext_value = var.aws_secret_access_key
}

# --- 3. Modificar el Archivo del Workflow (Inyectar el ECR URI) ---
resource "github_repository_file" "workflow_update" {
  repository          = github_repository.new_app_repo.name
  file                = ".github/workflows/build_push_ecr.yml"
  content             = templatefile("${path.module}/templates/workflow_template.tpl", {
    ecr_repo_uri = var.ecr_repository_url
    aws_region   = var.aws_region
  })
  commit_message      = "Terraform: Update ECR URI and Region for CI/CD"
  
  depends_on          = [
    github_repository.new_app_repo, 
    github_actions_secret.aws_key_id
  ]
}

output "http_clone_url" {
  description = "La URL de clonación HTTPS del nuevo repositorio creado, usada por EC2 User Data."
  value       = github_repository.new_app_repo.http_clone_url
}

output "repo_name" {
  description = "El nombre del nuevo repositorio, usado para referencias posteriores."
  value       = github_repository.new_app_repo.name
}