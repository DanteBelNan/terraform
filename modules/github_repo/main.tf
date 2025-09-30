

# --- Configuración del Proveedor GitHub ---
# El proveedor DEBE configurarse dentro del módulo,
# pero solo se aplica a los recursos de este módulo.
provider "github" {
  token = var.github_token
  owner = var.github_owner
}

# --- Recurso: Crear Repositorio a partir de Plantilla ---
resource "github_repository" "new_app_repo" {
  name        = lower(var.app_name) # Nombre del nuevo repo
  description = "Repositorio de la aplicación desplegada por Terraform."
  visibility  = "public"
  
  # Define el repositorio de plantilla (source)
  template {
    owner      = split("/", var.repo_template)[0]
    repository = split("/", var.repo_template)[1]
  }

  has_issues   = true
  has_projects = true
}

# --- Salidas del Módulo ---
# Exportamos la URL que necesita el módulo 'compute' (EC2)
output "http_clone_url" {
  description = "La URL de clonación HTTPS del nuevo repositorio creado."
  value       = github_repository.new_app_repo.http_clone_url
}

output "repo_name" {
  description = "El nombre del nuevo repositorio."
  value       = github_repository.new_app_repo.name
}