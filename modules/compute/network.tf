# Recurso: Elastic IP (EIP)
resource "aws_eip" "app_eip" {
  domain = "vpc"
  tags = {
    Name = "${var.app_name}-EIP"
  }
}

# Recurso: Security Group para la Instancia EC2
resource "aws_security_group" "app_sg" {
  name        = "${var.app_name}-sg"
  description = "Permite acceso SSH, HTTP y HTTPS"

  # Permite SSH (Puerto 22)
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  # Permite HTTP (Puerto 80) para NGINX/Web App
  ingress {
    description = "HTTP access for NGINX/Web App"
    from_port   = 80
    to_port     = 80
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
  ami           = "ami-0b1a0e980a3a7042a"
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  # Asocia la EIP a la instancia
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash

              # Variables de Entrada de Terraform
              GITHUB_SSH_PUB_KEY="${data.local_file.ssh_public_key.content}"
              REPO_URL="${var.github_repo_url}"
              BUILD_CMD="${var.build_command}"
              USER="ubuntu"
              REPO_DIR="/home/$USER/app_repo"
              
              # 1. Configuración Inicial (APT, Docker, Git, Compose Plugin)
              sudo apt update -y
              sudo apt install -y docker.io awscli git docker-compose-plugin # Agregamos el plugin de Compose
              sudo usermod -aG docker ubuntu 
              sudo systemctl start docker
              sudo systemctl enable docker

              # 2. Inyección de Clave SSH para Acceso a la Instancia
              mkdir -p /home/$USER/.ssh
              echo "$GITHUB_SSH_PUB_KEY" >> /home/$USER/.ssh/authorized_keys
              chmod 700 /home/$USER/.ssh
              chmod 600 /home/$USER/.ssh/authorized_keys
              chown -R $USER:$USER /home/$USER/.ssh
              
              # 3. Clonación de GitHub y Ejecución del Build (Docker Compose)
              
              # Establece el contexto al usuario ubuntu para permisos de clave SSH
              echo "Iniciando clonación de repositorio: $REPO_URL"
              
              # Clonar y construir como el usuario 'ubuntu'
              sudo -u $USER git clone "$REPO_URL" "$REPO_DIR"
              
              if [ -d "$REPO_DIR" ]; then
                echo "Clonación exitosa. Iniciando build con Docker Compose..."
                cd "$REPO_DIR"
                
                # Ejecutar el comando de build (docker compose up -d --build por defecto)
                sudo -u $USER sh -c "$BUILD_CMD"
                
                if [ $? -eq 0 ]; then
                  echo "Build del proyecto completado exitosamente."
                else
                  echo "ERROR: El comando de build falló. Revisar docker-compose.yml."
                fi
              else
                echo "ERROR: La clonación de Git falló. Verifica la URL y la clave SSH."
              fi
              EOF

  tags = {
    Name = "${var.app_name}-Server"
  }
}

# Asociación de la EIP 
resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.app_server.id
  allocation_id = aws_eip.app_eip.id
}