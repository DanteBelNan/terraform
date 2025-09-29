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
  ami           = data.aws_ami.ubuntu_latest.id
  instance_type = var.instance_type
  
  key_name      = "terraform-key" # Usamos la Key Pair de AWS para SSH

  vpc_security_group_ids = [aws_security_group.app_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash

              # Variables de Entrada de Terraform
              # Ya no necesitamos GITHUB_SSH_PUB_KEY ni la inyección de authorized_keys 
              # si usamos el key_name de AWS para login y HTTPS para Git Clone.
              # Mantenemos las variables de Git y Build
              REPO_URL="${var.github_repo_url}"
              BUILD_CMD="${var.build_command}"
              USER="ubuntu"
              REPO_DIR="/home/$USER/app_repo"
              
              # 1. Configuración Inicial (APT, Docker, Git, Compose Plugin) - CORREGIDO
              echo "Iniciando actualización e instalación de dependencias..."
              sudo apt update -y
              
              # Instalación de Docker, Git, AWS CLI
              sudo apt install -y docker.io awscli git 
              # Instalación del plugin de Docker Compose (comando correcto para 22.04)
              sudo apt install -y docker-compose-plugin 

              # Iniciar Docker y agregar el usuario 'ubuntu' al grupo 'docker'
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo usermod -aG docker $USER
              
              # 2. Inyección de Clave SSH para Acceso a la Instancia
              # MANTENER: Aunque usamos key_name, dejamos la inyección de la clave pública
              # del host de Terraform para mantener la compatibilidad con tu flujo de trabajo previo.
              # NOTA: En este punto, no es crucial, pero previene problemas si el usuario cambia el método.
              # Si cambiaste a HTTPS, esta sección no afecta el Git Clone, ¡pero mantenemos la compatibilidad!
              # Para simplificar MÁS, podríamos borrar la sección 2 completa, pero la dejaremos por ahora.
              # MODO SEGURO: Borramos la inyección, ya que el login es con key_name.
              
              # 3. Clonación de GitHub y Ejecución del Build (Docker Compose)
              
              echo "Iniciando clonación de repositorio: $REPO_URL"
              
              # Clonar y construir como el usuario 'ubuntu'
              # Si la URL es HTTPS, clonará sin pedir clave SSH.
              sudo -u $USER git clone "$REPO_URL" "$REPO_DIR"
              
              if [ -d "$REPO_DIR" ]; then
                echo "Clonación exitosa. Iniciando build con Docker Compose..."
                cd "$REPO_DIR"
                
                # Ejecutar el comando de build (usando sudo -u $USER para permisos correctos)
                # El usuario 'ubuntu' ya está en el grupo 'docker'
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
}

# Asociación de la EIP 
resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.app_server.id
  allocation_id = aws_eip.app_eip.id
}