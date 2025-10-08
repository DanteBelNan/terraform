terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.58.0"
    }
    github = {
      source  = "integrations/github"
      version = "6.0.0" 
    }
    jenkins = {
      source  = "taiidani/jenkins"
      version = "0.11.0"
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