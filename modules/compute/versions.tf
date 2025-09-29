# Define el proveedor y las versiones requeridas
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

}

# Configuración del proveedor
provider "aws" {
  region = "us-east-2" # Asegúrate de que esta sea la región que usarás
}
