# --- 1. Configuración del Proveedor AWS ---
provider "aws" {
  region = var.aws_region 
}

# --- 2. Data Source para Encontrar la Instancia Existente ---
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

# --- 3. Recurso Nulo para Iniciar la Instancia ---
resource "null_resource" "start_ec2_instance" {
  
  # Forzar la ejecución del comando en cada apply para iniciar la instancia.
  triggers = {
    timestamp = timestamp() 
  }

  provisioner "local-exec" {
    command = "aws ec2 start-instances --instance-ids ${data.aws_instance.app_server_to_start.id} --region ${var.aws_region}"
  }
  
  depends_on = [data.aws_instance.app_server_to_start]
}

# --- 4. Salida ---
output "instance_id_started" {
  value       = data.aws_instance.app_server_to_start.id
  description = "ID de la instancia que se inició."
}