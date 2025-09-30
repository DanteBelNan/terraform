variable "app_name" {
  description = "Application name and prefix for all resources."
  type        = string
}

# --- GitHub Variables (Read from TF_VAR_ environment) ---

variable "github_token" {
  description = "GitHub Personal Access Token (PAT) with 'repo' and 'workflow' scopes."
  type        = string
  sensitive   = true 
}

variable "github_owner" {
  description = "The GitHub organization or user where the repository will be created. (E.g., DanteBelNan)"
  type        = string
}

variable "repo_template" {
  description = "Full name of the template repository (owner/repo-name). E.g., DanteBelNan/node_template."
  type        = string
  validation {
    # CORRECTED VALIDATION MESSAGE to match the 'condition'
    condition     = contains(["DanteBelNan/node_template", "DanteBelNan/html_template"], var.repo_template) 
    error_message = "The value for repo_template must be one of the valid options: 'DanteBelNan/node_template' or 'DanteBelNan/html_template'."
  }
}

# --- AWS Compute Variables ---

variable "instance_type" {
  description = "The EC2 instance type to launch."
  type        = string
  default     = "t3.small" 
}

variable "build_command" {
  description = "Docker Compose CLI command to execute on the instance."
  type        = string
  default     = "docker compose up -d --build"
}

# --- AWS Access Keys for GitHub Secrets ---
variable "aws_access_key_id" {
  description = "AWS Access Key ID for authentication (used for GitHub Actions Secrets)."
  type        = string
  sensitive   = true 
}

variable "aws_secret_access_key" {
  description = "AWS Secret Access Key for authentication (used for GitHub Actions Secrets)."
  type        = string
  sensitive   = true 
}