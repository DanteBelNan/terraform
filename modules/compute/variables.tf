variable "app_name" {
  description = "Nombre base de la aplicación y prefijo para los recursos"
  type        = string
}

variable "instance_type" {
  description = "El tipo de instancia EC2 para el servidor"
  type        = string
}

variable "github_repo_url" {
  description = "URL SSH del repositorio de GitHub a clonar"
  type        = string
}

variable "build_command" {
  description = "Comando CLI para construir y levantar la aplicación"
  type        = string
}