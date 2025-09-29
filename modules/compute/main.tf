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
    from_port   = 8080
    to_port     = 8080
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
  ami           = data.aws_ami.ubuntu_latest.id
  instance_type = var.instance_type
  
  key_name      = "terraform-key" # Usamos la Key Pair de AWS para SSH

  vpc_security_group_ids = [aws_security_group.app_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash

              # Variables de Entrada de Terraform
              REPO_URL="${var.github_repo_url}"
              BUILD_CMD="${var.build_command}"
              USER="ubuntu"
              REPO_DIR="/home/$USER/app_repo"
              
              # 1. Configuración Inicial (APT, Docker, Git, Compose Plugin) - REVISADO
              echo "Iniciando actualización e instalación de dependencias..."
              sudo apt update -y
              
              # Instalación de paquetes básicos (Git, AWS CLI)
              sudo apt install -y awscli git 
              
              # Instalación de Docker y Docker Compose V2 (Método Oficial, más robusto)
              echo "Instalando Docker Engine y Compose Plugin..."
              # Instalar Docker usando el script de conveniencia de Docker
              curl -fsSL https://get.docker.com -o get-docker.sh
              sudo sh get-docker.sh
              
              # Iniciar Docker
              sudo systemctl start docker
              sudo systemctl enable docker
              
              # Agregar el usuario 'ubuntu' al grupo 'docker' para ejecutar comandos sin sudo
              # Esto requiere re-login, pero usaremos 'sudo -u $USER' en la ejecución, por si acaso.
              sudo usermod -aG docker $USER
              
              # Para que los cambios de grupo tomen efecto inmediatamente en el script (aunque no es perfecto)
              newgrp docker
              
              # 3. Clonación de GitHub y Ejecución del Build (Docker Compose)
              
              echo "Iniciando clonación de repositorio: $REPO_URL"
              
              # Clonar y construir como el usuario 'ubuntu'
              sudo -u $USER git clone "$REPO_URL" "$REPO_DIR"
              
              if [ -d "$REPO_DIR" ]; then
                echo "Clonación exitosa. Iniciando build con Docker Compose..."
                cd "$REPO_DIR"
                
                # Ejecutar el comando de build. Docker Compose V2 se instala como 'docker compose'.
                # Lo ejecutamos como el usuario 'ubuntu' para respetar permisos del repo clonado.
                sudo -u $USER sh -c "$BUILD_CMD"
                
                if [ $? -eq 0 ]; then
                  echo "Build del proyecto completado exitosamente."
                else
                  echo "ERROR: El comando de build falló. Revisar docker-compose.yml."
                fi
              else
                echo "ERROR: La clonación de Git falló. Verifica la URL."
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