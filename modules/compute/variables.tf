variable "app_name" {
  description = "Nombre base de la aplicación y prefijo para los recursos"
  type        = string
}

variable "instance_type" {
  description = "El tipo de instancia EC2 para el servidor"
  type        = string
}