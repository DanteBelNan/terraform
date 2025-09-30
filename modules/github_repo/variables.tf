variable "app_name" {
  description = "Nombre de la aplicación para nombrar el nuevo repositorio."
  type        = string
}

variable "github_token" {
  description = "Token de Acceso Personal de GitHub (PAT)."
  type        = string
  sensitive   = true 
}

variable "github_owner" {
  description = "Nombre de la organización o usuario de GitHub."
  type        = string
}

variable "repo_template" {
  description = "Nombre completo del repositorio de plantilla (owner/repo-name)."
  type        = string
  validation {
    condition     = length(regexall("/", var.repo_template)) == 1
    error_message = "El valor para repo_template debe ser 'owner/repo-name'."
  }
}