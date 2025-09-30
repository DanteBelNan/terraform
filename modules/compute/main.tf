# Resource: Elastic IP (EIP)
resource "aws_eip" "app_eip" {
  domain = "vpc"
  tags = {
    Name = "${var.app_name}-EIP"
  }
}

resource "aws_security_group" "app_sg" {
  name        = "${var.app_name}-sg"
  description = "Allows SSH, HTTP, and HTTPS access"

  # Allow SSH (Port 22)
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  ingress {
    description = "Web App access for NGINX/Application"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  
  # Allow all outbound traffic
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

# Resource: EC2 Instance
resource "aws_instance" "app_server" {
  ami           = data.aws_ami.ubuntu_latest.id
  instance_type = var.instance_type
  
  key_name      = "terraform-key"

  vpc_security_group_ids = [aws_security_group.app_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash

              # Terraform Input Variables
              REPO_URL="${var.github_repo_url}"
              BUILD_CMD="${var.build_command}"
              USER="ubuntu"
              REPO_DIR="/home/$USER/app_repo"
              
              # 1. Initial Configuration (APT, Docker, Git, Compose Plugin)
              echo "Starting update and dependency installation..."
              sudo apt update -y
              
              # Install basic packages (Git, AWS CLI)
              sudo apt install -y awscli git 
              
              # Install Docker and Docker Compose V2
              echo "Installing Docker Engine and Compose Plugin..."
              # Install Docker using the official convenience script
              curl -fsSL https://get.docker.com -o get-docker.sh
              sudo sh get-docker.sh
              
              # Start Docker
              sudo systemctl start docker
              sudo systemctl enable docker
              
              # Add 'ubuntu' user to the 'docker' group
              sudo usermod -aG docker $USER
              
              # Apply group changes immediately
              newgrp docker
              
              # 2. GitHub Cloning and Build Execution (Docker Compose)
              
              echo "Starting repository cloning: $REPO_URL"
              
              # Clone and build as the 'ubuntu' user
              sudo -u $USER git clone "$REPO_URL" "$REPO_DIR"
              
              if [ -d "$REPO_DIR" ]; then
                echo "Cloning successful. Starting build with Docker Compose..."
                cd "$REPO_DIR"
                
                # Execute the build command. Docker Compose V2 is installed as 'docker compose'.
                # Execute as the 'ubuntu' user to respect permissions.
                sudo -u $USER sh -c "$BUILD_CMD"
                
                if [ $? -eq 0 ]; then
                  echo "Project build completed successfully."
                else
                  echo "ERROR: The build command failed. Check docker-compose.yml."
                fi
              else
                echo "ERROR: Git cloning failed. Check the URL."
              fi
              EOF

  tags = {
    Name = "${var.app_name}-Server"
  }
}

# EIP Association 
resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.app_server.id
  allocation_id = aws_eip.app_eip.id
}