# environments/dev/variables.tf
# Define las variables de entrada para este entorno específico.

variable "app_name" {
  description = "Nombre base de la aplicación para el entorno DEV"
  type        = string
  default     = "DevWebApp" 
}

variable "instance_type" {
  description = "El tipo de instancia EC2 para DEV (mantener t2.micro por costo)"
  type        = string
  default     = "t2.micro" 
}