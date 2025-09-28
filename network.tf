# Recurso: Elastic IP (EIP)
resource "aws_eip" "app_eip" {
  vpc = true # Provisiona la EIP para ser usada en una VPC
  tags = {
    Name = "${var.app_name}-EIP"
  }
}

# Recurso: Security Group para la Instancia EC2
resource "aws_security_group" "app_sg" {
  name        = "${var.app_name}-sg"
  description = "Permite acceso SSH y HTTP/S"

  # Permite SSH desde CUALQUIER lugar (temporal y para pruebas, luego usar tu IP)
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  
  # Permite tráfico de salida a cualquier lugar
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" 
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-SecurityGroup"
  }
}

# Recurso: Instancia EC2
resource "aws_instance" "app_server" {
  ami           = "ami-053b0a5351a2d8a0c" # ID de una AMI de Ubuntu 22.04 LTS (busca la actual en tu región)
  instance_type = var.instance_type
  key_name      = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  # Asocia la EIP a la instancia
  associate_public_ip_address = true
  
  tags = {
    Name = "${var.app_name}-Server"
  }
}

# Asociación de la EIP (aunque EC2 ya tiene IP pública, esta garantiza que sea fija)
resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.app_server.id
  allocation_id = aws_eip.app_eip.id
}
