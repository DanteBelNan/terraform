# modules/compute/main.tf

# Resource: Elastic IP (EIP)
resource "aws_eip" "app_eip" {
  domain = "vpc"
  tags = {
    Name = "${var.app_name}-EIP"
  }
}

# Resource: Security Group for the EC2 Instance
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

  # Allow Custom Web App Port (Port 8080) 
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
              IMAGE_URI="${var.ecr_image_uri}"
              RUN_CMD="${var.run_command}"
              REGION="${var.aws_region}"
              
              # 1. Initial Configuration (APT, Docker, AWS CLI)
              echo "Starting update and dependency installation..."
              sudo apt update -y
              
              # Install packages (AWS CLI is CRUCIAL for ECR login)
              sudo apt install -y awscli git 
              
              # Install Docker Engine (NO Docker Compose needed)
              echo "Installing Docker Engine..."
              curl -fsSL https://get.docker.com -o get-docker.sh
              sudo sh get-docker.sh
              sudo systemctl start docker
              sudo systemctl enable docker
              
              # Add 'ubuntu' user to the 'docker' group
              sudo usermod -aG docker ubuntu
              
              # Wait a moment for Docker to be fully ready
              sleep 10
              
              # 2. Authenticate to ECR and Pull Image
              echo "Authenticating to ECR in region $REGION..."
              
              # Get ECR login token and log Docker into the registry
              AUTH_TOKEN=$(aws ecr get-login-password --region $REGION)
              REGISTRY=$(echo "$IMAGE_URI" | cut -d/ -f1)
              
              sudo docker login --username AWS --password $AUTH_TOKEN $REGISTRY
              
              if [ $? -eq 0 ]; then
                echo "ECR login successful."
                
                # 3. Pull the Image from ECR
                echo "Pulling image: $IMAGE_URI"
                sudo docker pull "$IMAGE_URI"
                
                if [ $? -eq 0 ]; then
                  echo "Image pull successful. Starting application..."

                  # 4. Stop and Run the Container (ensures clean restart)
                  sudo docker stop ${var.app_name} || true
                  sudo docker rm ${var.app_name} || true
                  
                  # Execute the Docker run command provided by the Terraform variable
                  sudo sh -c "$RUN_CMD --name ${var.app_name} $IMAGE_URI"
                  
                  if [ $? -eq 0 ]; then
                    echo "Container started successfully."
                  else
                    echo "ERROR: Docker run command failed."
                  fi
                  
                else
                  echo "ERROR: Docker Pull failed. Check IMAGE_URI and ECR permissions."
                fi
              else
                echo "ERROR: ECR login failed. Check IAM permissions or Region."
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