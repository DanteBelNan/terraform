variable "app_name" {
  description = "Application name. Must match the Name tag used to find the instance."
  type        = string
}

variable "aws_region" {
  description = "AWS Region where the instance will be searched and started."
  type        = string
  default     = "us-east-2"
}