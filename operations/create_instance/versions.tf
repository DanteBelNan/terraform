terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket         = "dbeltran-bucket-unic" 
    key            = "dev/base_infra/terraform.tfstate"
    region         = "us-east-2" 
    dynamodb_table = "terraform-state-locks" 
    encrypt        = true
  }
}