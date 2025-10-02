variable "app_name" {
  description = "Application name used for naming the ECR repositories."
  type        = string
}

variable "repo_names" {
  description = "List of repository names to create (e.g., ['node-repo', 'nginx-repo', 'cli-repo'])."
  type        = list(string)
  default     = ["node-repo", "nginx-repo", "cli-repo"] 
}