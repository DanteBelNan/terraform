# modules/github_repo/variables.tf

# --- Variables de Configuración de GitHub ---

variable "app_name" {
  description = "Nombre de la aplicación para nombrar el nuevo repositorio."
  type        = string
}

variable "github_token" {
  description = "Token de Acceso Personal de GitHub (PAT) con scopes 'repo' y 'workflow'."
  type        = string
  sensitive   = true 
}

variable "github_owner" {
  description = "Nombre de la organización o usuario de GitHub donde se creará el repositorio."
  type        = string
}

variable "repo_template" {
  description = "Nombre completo del repositorio de plantilla (owner/repo-name). Ej: DanteBelNan/node_postgres."
  type        = string
}

# --- Variables para la Configuración de CI/CD (Secrets y ECR) ---

variable "ecr_repository_url" {
  description = "URI completo del ECR creado, usado para inyectar en el workflow de GitHub Actions."
  type        = string
}

variable "aws_access_key_id" {
  description = "Access Key ID para configurar GitHub Secrets de AWS."
  type        = string
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "Secret Access Key para configurar GitHub Secrets de AWS."
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "Región de AWS, usada para inyectar en el workflow."
  type        = string
  default     = "us-east-2"
}