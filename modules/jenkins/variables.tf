variable "app_name" {
  description = "The application name used for resource naming (e.g., ci-server-jenkins)."
  type        = string
}

variable "instance_type" {
  description = "The EC2 instance type for the Jenkins server."
  type        = string
  default     = "t2.micro" # Using t2.micro for basic testing
}

variable "key_name" {
  description = "The name of the existing AWS Key Pair for SSH access (e.g., terraform-key)."
  type        = string
  default     = "terraform-key" 
}