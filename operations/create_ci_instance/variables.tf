variable "app_name" {
  description = "The name for the CI infrastructure components (e.g., jenkins)."
  type        = string
  default     = "jenkins"
}

variable "aws_region" {
  description = "The AWS region where resources are deployed."
  type        = string
  default     = "us-east-2"
}

variable "instance_type" {
  description = "The EC2 instance type for the Jenkins server."
  type        = string
  default     = "t2.micro"
}