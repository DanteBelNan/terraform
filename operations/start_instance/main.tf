# --- 1. AWS Provider Configuration ---
provider "aws" {
  region = var.aws_region 
}

# --- 2. Data Source to Find the Existing Instance (Stopped) ---
data "aws_instance" "app_server_to_start" {
  filter {
    name   = "tag:Name"
    values = ["${var.app_name}-Server"]
  }
  filter {
    name   = "instance-state-name"
    values = ["stopped"]
  }
}

# --- 3. Null Resource to Start the Instance ---
resource "null_resource" "start_ec2_instance" {
  
  # Force command execution on every apply to start the instance.
  triggers = {
    timestamp = timestamp() 
  }

  provisioner "local-exec" {
    # Calls the AWS CLI to start the instance using its ID and region.
    command = "aws ec2 start-instances --instance-ids ${data.aws_instance.app_server_to_start.id} --region ${var.aws_region}"
  }
  
  # Ensures data source is resolved before attempting to run the command.
  depends_on = [data.aws_instance.app_server_to_start]
}

# --- 4. Output ---
output "instance_id_started" {
  value       = data.aws_instance.app_server_to_start.id
  description = "ID of the instance that was started."
}