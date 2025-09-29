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
  ami           = "ami-053b0a5351a2d8a0c" 
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  # Asocia la EIP a la instancia
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash

              # Leemos la clave desde el data source
              GITHUB_SSH_PUB_KEY="${data.local_file.ssh_public_key.content}"
              USER="ubuntu"

              # Rutina de inyección de clave
              mkdir -p /home/$USER/.ssh
              echo "$GITHUB_SSH_PUB_KEY" >> /home/$USER/.ssh/authorized_keys
              chmod 700 /home/$USER/.ssh
              chmod 600 /home/$USER/.ssh/authorized_keys
              chown -R $USER:$USER /home/$USER/.ssh

              # Instalación de software esencial
              sudo apt update -y
              sudo apt install -y docker.io awscli git
              sudo usermod -aG docker ubuntu 
              sudo systemctl start docker
              sudo systemctl enable docker

              echo "Instancia configurada y clave SSH inyectada."
              EOF

  tags = {
    Name = "${var.app_name}-Server"
  }
}


# Asociación de la EIP (aunque EC2 ya tiene IP pública, esta garantiza que sea fija)
resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.app_server.id
  allocation_id = aws_eip.app_eip.id
}
