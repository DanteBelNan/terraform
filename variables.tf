# Variable para el nombre base de la aplicación
variable "app_name" {
  description = "Nombre base de la aplicación y prefijo para los recursos"
  type        = string
  default     = "MyWebApp" 
}

# Variable para el tipo de instancia EC2
variable "instance_type" {
  description = "El tipo de instancia EC2"
  type        = string
  default     = "t2.micro" 
}

# Variable para tu clave SSH (la que descargaste)
variable "key_pair_name" {
  description = "Nombre del Key Pair de AWS para la conexión SSH"
  type        = string
  default     = "terraform-key" # Usa el nombre de tu clave
}
