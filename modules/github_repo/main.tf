# --- GitHub Provider Configuration ---
provider "github" {
  token = var.github_token
  owner = var.github_owner 
}

# --- 1. Create Repository from Template ---
resource "github_repository" "new_app_repo" {
  name        = lower(var.app_name)
  description = "Application repository deployed by Terraform."
  visibility  = "public"
  
  template {
    owner      = split("/", var.repo_template)[0]
    repository = split("/", var.repo_template)[1]
  }

  has_issues   = true
  has_projects = true
}

# --- 2. Inject GitHub Actions Secrets (AWS Credentials) ---
resource "github_actions_secret" "aws_key_id" {
  repository      = github_repository.new_app_repo.name
  secret_name     = "AWS_ACCESS_KEY_ID"
  plaintext_value = var.aws_access_key_id
}

resource "github_actions_secret" "aws_secret_key" {
  repository      = github_repository.new_app_repo.name
  secret_name     = "AWS_SECRET_ACCESS_KEY"
  plaintext_value = var.aws_secret_access_key
}

# --- 3. Update README.md (Conditional: Only for node_template) ---
resource "github_repository_file" "readme_update" {
  count               = var.repo_template == "DanteBelNan/node_template" ? 1 : 0
  
  repository          = github_repository.new_app_repo.name
  file                = "README.md"
  
  content             = templatefile("${path.module}/templates/readme_template.tpl", {
    app_name      = lower(var.app_name)
    github_owner  = var.github_owner
  })
  
  commit_message      = "Terraform: Update README.md with actual application name."
  
  depends_on          = [github_repository.new_app_repo]
}

# --- 4. Update Workflow File (Inject ECR URI) ---
resource "github_repository_file" "workflow_update" {
  repository          = github_repository.new_app_repo.name
  file                = ".github/workflows/build_push_ecr.yml"
  content             = templatefile("${path.module}/templates/workflow_template.tpl", {
    ecr_repo_uri = var.ecr_repository_url
    aws_region   = var.aws_region
  })
  commit_message      = "Terraform: Update ECR URI and Region for CI/CD"
  
  depends_on          = [
    github_repository.new_app_repo, 
    github_actions_secret.aws_key_id
  ]
}

# --- Module Outputs ---
output "http_clone_url" {
  description = "The HTTPS clone URL of the new repository, used by EC2 User Data."
  value       = github_repository.new_app_repo.http_clone_url
}

output "repo_name" {
  description = "The name of the new repository."
  value       = github_repository.new_app_repo.name
}