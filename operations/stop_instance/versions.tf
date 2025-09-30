terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Usar la misma versión que en 'create_instance'
    }
  }
}