variable "app_name" {
  description = "Base application name and prefix for all resources."
  type        = string
}

variable "instance_type" {
  description = "The EC2 instance type for the server."
  type        = string
}

# --- Image and Region for Pull ---
variable "ecr_image_uri" {
  description = "Full URI of the Docker image in ECR (e.g., 123.dkr.ecr.us-east-2.amazonaws.com/myapp:latest)."
  type        = string
}

variable "aws_region" {
  description = "AWS Region of the ECR registry."
  type        = string
  default     = "us-east-2"
}

# --- Command to RUN the single container ---
variable "run_command" {
  description = "The Docker run command to execute the container after pulling (e.g., docker run -d -p 8080:80)."
  type        = string
  default     = "sudo docker run -d -p 8080:80 --restart=always" 
}