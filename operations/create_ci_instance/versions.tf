terraform {
  required_version = ">= 1.0"
  
  required_providers {
    # AWS Provider is required to create the Jenkins EC2 instance, IAM role, and Security Group.
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    
    # Although Jenkins itself doesn't use GitHub resources, 
    # the GitHub provider is typically included at the root for overall consistency 
    # and if any other future CI/CD metadata were to be managed here.
    # However, for this specific CI instance creation, only AWS is strictly necessary.
    # We include it here for completeness if you decide to manage GitHub settings for the CI server later.
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}