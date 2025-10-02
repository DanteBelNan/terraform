# ----------------------------------------------------
# 1. DATA SOURCES
# ----------------------------------------------------

# 1.1 Latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  owners = ["099720109477"]
}

# 1.2 Default VPC
data "aws_vpc" "default" {
  default = true
}

# 1.3 Subnets
data "aws_subnets" "all" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ----------------------------------------------------
# 2. IAM ROLE (SSM Command + Permissions)
# ----------------------------------------------------
# This role allows the Jenkins EC2 instance to be managed via SSM.

resource "aws_iam_role" "jenkins_role" {
  name = "${var.app_name}-jenkins-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

# Attach SSM Managed Instance Core Policy (Crucial for running deployments via SSM)
resource "aws_iam_role_policy_attachment" "ssm_managed_instance" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "${var.app_name}-jenkins-profile"
  role = aws_iam_role.jenkins_role.name
}

# ----------------------------------------------------
# 3. NETWORK & SECURITY GROUP
# ----------------------------------------------------

# 3.1 Security Group for Jenkins
resource "aws_security_group" "jenkins_sg" {
  name        = "${var.app_name}-jenkins-sg"
  vpc_id      = data.aws_vpc.default.id

  # Ingress: SSH (Port 22) - For management
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Ingress: Jenkins Web UI (Port 8080)
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress: All traffic (Jenkins needs to access GitHub, ECR, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ----------------------------------------------------
# 4. EC2 INSTANCE (Jenkins Server)
# ----------------------------------------------------
resource "aws_instance" "jenkins_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  
  # Use the static key provided by the variable
  key_name      = var.key_name 
  
  subnet_id     = tolist(data.aws_subnets.all.ids)[0] 
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  iam_instance_profile = aws_iam_instance_profile.jenkins_profile.name

  # User Data to install Java, Jenkins, and Docker
  user_data = <<-EOF
              #!/bin/bash
              
              echo "--- 1. Installing Java and Jenkins ---"
              export DEBIAN_FRONTEND=noninteractive
              
              # 1.1 Install Java (JDK 17)
              sudo apt update -y
              sudo apt install -y openjdk-17-jdk
              
              # 1.2 Install Jenkins
              curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
                /usr/share/keyrings/jenkins-keyring.asc > /dev/null
              echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
                https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
                /etc/apt/sources.list.d/jenkins.list > /dev/null
              sudo apt-get update
              sudo apt-get install -y jenkins
              
              echo "--- 2. Installing AWS/Docker Dependencies for Builds ---"
              # 2.1 AWS CLI (for SSM and ECR interaction) and Git
              sudo apt install -y awscli git
              
              # 2.2 Docker and Docker Compose (Jenkins needs Docker for builds)
              sudo apt install -y docker.io docker-compose-plugin
              
              # 2.3 Add users to docker group
              sudo usermod -aG docker ubuntu
              sudo usermod -aG docker jenkins
              
              # 2.4 Start services
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo systemctl enable jenkins
              sudo systemctl start jenkins
              
              echo "--- Jenkins Provisioning Complete ---"
              EOF

  tags = {
    Name = "${var.app_name}-Jenkins-Server"
    Environment = "CI/CD"
  }
}

# ----------------------------------------------------
# 5. ELASTIC IP & OUTPUTS (Corregido: Outputs movidos a main.tf)
# ----------------------------------------------------

# 5.1 Elastic IP
resource "aws_eip" "jenkins_ip" {
  instance = aws_instance.jenkins_server.id
  tags = {
    Name = "${var.app_name}-Jenkins-EIP"
  }
}

output "instance_id" {
  description = "The Jenkins server instance ID."
  value       = aws_instance.jenkins_server.id
}

output "public_ip" {
  description = "The public IP address of the Jenkins server."
  value       = aws_eip.jenkins_ip.public_ip
}