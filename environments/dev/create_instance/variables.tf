variable "app_name" {
  description = "Nombre base de la aplicación para el entorno DEV"
  type        = string
}

variable "instance_type" {
  description = "El tipo de instancia EC2 para DEV (mantener t2.micro por costo)"
  type        = string
  default     = "t2.micro" 
}

variable "github_repo_url" {
  description = "URL SSH del repositorio de GitHub a clonar"
  type        = string
}

variable "build_command" {
  description = "Comando CLI para construir y levantar la aplicación (Docker Compose)"
  type        = string
  default     = "docker compose up -d --build" 
}