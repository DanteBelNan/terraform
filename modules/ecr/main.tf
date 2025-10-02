resource "aws_ecr_repository" "app_repo" {
  name                 = "${lower(var.app_name)}-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.app_name}-ecr"
  }
}

output "repository_url" {
  description = "The complete ECR URI."
  value       = aws_ecr_repository.app_repo.repository_url
}