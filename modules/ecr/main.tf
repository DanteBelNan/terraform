resource "aws_ecr_repository" "app_repos" {
  for_each             = toset(var.repo_names)
  
  name                 = "${lower(var.app_name)}-${each.value}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.app_name}-${each.value}-ecr"
  }
}

output "repository_urls" {
  description = "Map of all ECR URIs created."
  value       = { for name, repo in aws_ecr_repository.app_repos : name => repo.repository_url }
}