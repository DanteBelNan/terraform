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
  default     = "t2.micro" 
}

variable "build_command" {
  description = "The Docker Compose command to run the application (PULL and UP)."
  type        = string
  default     = "sudo docker compose -f docker-compose.deploy.yml pull && sudo docker compose -f docker-compose.deploy.yml up -d"
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

variable "jenkins_admin_user" {
  description = "The admin username for the Jenkins server."
  type        = string
  default     = "admin"
}

variable "jenkins_admin_token" {
  description = "The API Token for the Jenkins admin user."
  type        = string
  sensitive   = true

}