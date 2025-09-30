# operations/start_instance/variables.tf

variable "app_name" {
  description = "Nombre de la aplicación. Debe coincidir con la tag Name usada para buscar la instancia."
  type        = string
}

variable "aws_region" {
  description = "Región de AWS donde se buscará e iniciará la instancia."
  type        = string
  default     = "us-east-2"
}