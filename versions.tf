# Define el proveedor y las versiones requeridas
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Configuración del Backend para almacenamiento remoto del estado
  backend "s3" {
    # Cambia este valor por un nombre de bucket globalmente único
    bucket         = "dbeltran-bucket-unic" 
    key            = "dev/base_infra/terraform.tfstate"
    region         = "us-east-1"
    
    # Nombre de la tabla de DynamoDB (para state locking)
    dynamodb_table = "terraform-state-locks" 
    encrypt        = true
  }
}

# Configuración del proveedor
provider "aws" {
  region = "us-east-2" # Asegúrate de que esta sea la región que usarás
}
