variable "app_name" {
  description = "Base application name and prefix for all resources."
  type        = string
}

variable "instance_type" {
  description = "The EC2 instance type for the server."
  type        = string
}

variable "aws_region" {
  description = "AWS Region of the ECR registry."
  type        = string
  default     = "us-east-2"
}

# --- Command to RUN the single container ---
variable "build_command" {
  description = "The Docker Compose command to run the application (now a PULL and UP)."
  type        = string
  default     = "sudo docker compose -f docker-compose.deploy.yml pull && sudo docker compose -f docker-compose.deploy.yml up -d"
}