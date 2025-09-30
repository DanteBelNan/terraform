# --- 1. AWS Provider Configuration ---
provider "aws" {
  region = var.aws_region 
}

# --- 2. Data Source to Find the Existing Instance (Running) ---
data "aws_instance" "app_server_to_stop" {
  filter {
    name   = "tag:Name"
    values = ["${var.app_name}-Server"]
  }
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

# --- 3. Null Resource to Stop the Instance ---
resource "null_resource" "stop_ec2_instance" {
  
  # Force command execution on every apply to stop the instance.
  triggers = {
    timestamp = timestamp() 
  }

  provisioner "local-exec" {
    # Calls the AWS CLI to stop the instance using its ID and region.
    command = "aws ec2 stop-instances --instance-ids ${data.aws_instance.app_server_to_stop.id} --region ${var.aws_region}"
  }
  
  # Ensures data source is resolved before attempting to run the command.
  depends_on = [data.aws_instance.app_server_to_stop]
}

# --- 4. Output ---
output "instance_id_stopped" {
  value       = data.aws_instance.app_server_to_stop.id
  description = "ID of the instance that was stopped."
}