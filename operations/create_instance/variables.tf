variable "app_name" {
  description = "Nombre de la aplicación y prefijo para todos los recursos."
  type        = string
}

# --- Variables de GitHub (Leídas del entorno TF_VAR_) ---

variable "github_token" {
  description = "Token de Acceso Personal (PAT) de GitHub con scope 'repo' para crear repositorios."
  type        = string
  sensitive   = true 
}

variable "github_owner" {
  description = "Nombre de la organización o usuario de GitHub donde se creará el repositorio. (Ej. DanteBelNan)"
  type        = string
}

variable "repo_template" {
  description = "Nombre completo del repositorio de plantilla (owner/repo-name). Ej: DanteBelNan/node_postgres."
  type        = string
  validation {
    condition     = contains(["DanteBelNan/node_template", "DanteBelNan/html_template"], var.repo_template) #Diferentes templates
    error_message = "El valor para repo_template debe ser una de las opciones válidas: 'DanteBelNan/node_postgres' o 'DanteBelNan/play_chat'."
  }
}

# --- Variables de Compute ---

variable "instance_type" {
  description = "Tipo de instancia EC2 a lanzar."
  type        = string
  default     = "t3.small" 
}

variable "build_command" {
  description = "Comando de Docker Compose a ejecutar en la instancia."
  type        = string
  default     = "docker compose up -d --build"
}

# --- Variables de AWS acces key ---
variable "aws_access_key_id" {
  description = "Access Key ID para autenticación de AWS (para GitHub Actions)."
  type        = string
  sensitive   = true 
}

variable "aws_secret_access_key" {
  description = "Secret Access Key para autenticación de AWS (para GitHub Actions)."
  type        = string
  sensitive   = true 
}