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

variable "run_command" {
  description = "Docker run command to execute the container after pull (e.g., docker run -d -p 8080:80)."
  type        = string
  default     = "sudo docker run -d -p 8080:80 --restart=always"
}

# --- AWS Access Keys for GitHub Secrets ---
variable "aws_access_key_id" {
  description = "AWS Access Key ID for authentication (used for GitHub Actions Secrets)."
  type        = string
  sensitive   = true 
}

variable "aws_secret_access_key" {
  description = "Secret Access Key for authentication (used for GitHub Actions Secrets)."
  type        = string
  sensitive   = true 
}