# --- GitHub Configuration Variables ---

variable "app_name" {
  description = "Application name used for naming the new repository."
  type        = string
}

variable "github_token" {
  description = "GitHub Personal Access Token (PAT) with 'repo' and 'workflow' scopes."
  type        = string
  sensitive   = true 
}

variable "github_owner" {
  description = "The GitHub organization or user where the repository will be created."
  type        = string
}

variable "repo_template" {
  description = "Full name of the template repository (owner/repo-name). E.g., DanteBelNan/node_template."
  type        = string
  validation {
    condition     = contains(["DanteBelNan/node_template", "DanteBelNan/html_template"], var.repo_template)
    error_message = "The value for repo_template must be one of the valid options: 'DanteBelNan/node_template' or 'DanteBelNan/html_template'."
  }
}

# --- CI/CD Configuration Variables (Secrets and ECR) ---

variable "ecr_repository_url" {
  description = "Full URI of the ECR created, used for injection into the GitHub Actions workflow."
  type        = string
}

variable "aws_access_key_id" {
  description = "AWS Access Key ID for configuring GitHub Secrets."
  type        = string
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS Secret Access Key for configuring GitHub Secrets."
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "AWS Region, used for injection into the workflow."
  type        = string
  default     = "us-east-2"
}