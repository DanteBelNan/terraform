# --- 1. Configuración del Proveedor AWS ---
provider "aws" {
  region = var.aws_region 
}

# --- 2. Data Source para Encontrar la Instancia Existente ---
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

# --- 3. Recurso Nulo para Detener la Instancia ---
resource "null_resource" "stop_ec2_instance" {
  
  # Forzar la ejecución del comando en cada apply para detener la instancia.
  triggers = {
    timestamp = timestamp() 
  }

  provisioner "local-exec" {
    command = "aws ec2 stop-instances --instance-ids ${data.aws_instance.app_server_to_stop.id} --region ${var.aws_region}"
  }
  
  depends_on = [data.aws_instance.app_server_to_stop]
}

# --- 4. Salida ---
output "instance_id_stopped" {
  value       = data.aws_instance.app_server_to_stop.id
  description = "ID de la instancia que se detuvo."
}