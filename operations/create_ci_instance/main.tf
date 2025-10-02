# operations/create_ci_instance/main.tf

# --- AWS Provider Configuration ---
provider "aws" {
  region = var.aws_region
}

# --- 1. JENKINS SERVER MODULE ---
module "jenkins_server" {
  source        = "../../modules/jenkins"
  app_name      = var.app_name
  instance_type = var.instance_type
  # key_name uses the default "terraform-key" from the module's variables.tf
}

# ----------------------------------------------------
# OUTPUTS
# ----------------------------------------------------

output "jenkins_public_ip" {
  description = "Public IP address of the Jenkins server. Access on port 8080."
  value       = module.jenkins_server.public_ip
}

output "jenkins_instance_id" {
  description = "The Jenkins server instance ID."
  value       = module.jenkins_server.instance_id
}