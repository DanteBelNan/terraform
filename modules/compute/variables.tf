variable "app_name" {
  description = "Base application name and prefix for all resources."
  type        = string
}

variable "instance_type" {
  description = "The EC2 instance type for the server."
  type        = string
}

variable "github_repo_url" {
  description = "HTTPS URL of the GitHub repository to clone."
  type        = string
}

variable "build_command" {
  description = "CLI command to build and launch the application (e.g., docker compose up -d)."
  type        = string
}