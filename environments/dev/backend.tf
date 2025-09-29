backend "s3" {
  bucket         = "dbeltran-bucket-unic" 
  # Path único para el entorno DEV
  key            = "dev/base_infra/terraform.tfstate"
  region         = "us-east-2" 
  
  # Tabla de DynamoDB para el state locking
  dynamodb_table = "terraform-state-locks" 
  encrypt        = true
}