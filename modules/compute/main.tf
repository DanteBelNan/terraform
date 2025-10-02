# 1. DATA SOURCES

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

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.default.id
}

# 1.3 Local SSH Public Key
data "local_file" "ssh_public_key" {
  filename = "/home/ubuntu/.ssh/id_rsa.pub"
}

# 2. IAM ROLE (ECR Read Permissions)

# 2.1 IAM Role Definition
resource "aws_iam_role" "ecr_reader_role" {
  name = "${var.app_name}-ecr-reader-role"
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

# 2.2 Attach ECR Read-Only Policy
resource "aws_iam_role_policy_attachment" "ecr_readonly_attach" {
  role       = aws_iam_role.ecr_reader_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# 2.3 Create IAM Instance Profile
resource "aws_iam_instance_profile" "ecr_reader_profile" {
  name = "${var.app_name}-ecr-reader-profile"
  role = aws_iam_role.ecr_reader_role.name
}

# 3. NETWORK & SSH KEY

# 3.1 Security Group
resource "aws_security_group" "app_sg" {
  name        = "${var.app_name}-sg"
  vpc_id      = data.aws_vpc.default.id

  # Ingress: SSH (Port 22)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Ingress: Application Port (8080)
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress: All traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3.2 Key Pair for SSH
resource "aws_key_pair" "deployer_key" {
  key_name   = "${var.app_name}-deployer-key"
  public_key = data.local_file.ssh_public_key.content
}

# 4. EC2 INSTANCE
resource "aws_instance" "app_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.deployer_key.key_name 
  subnet_id     = tolist(data.aws_subnet_ids.all.ids)[0]
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  iam_instance_profile = aws_iam_instance_profile.ecr_reader_profile.name

  user_data = <<-EOF
              #!/bin/bash

              GITHUB_REPO_URL="${var.github_repo_url}"
              BUILD_CMD="${var.build_command}"
              AWS_REGION="${var.aws_region}" 
              REPO_DIR="/home/ubuntu/${var.app_name}"
              
              # 1. Install Dependencies (Docker, Git, AWS CLI, Docker Compose)
              sudo apt update -y
              sudo apt install -y awscli git docker-compose-plugin 
              curl -fsSL https://get.docker.com -o get-docker.sh
              sudo sh get-docker.sh
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo usermod -aG docker ubuntu
              sleep 10
              
              # 2. Authenticate to ECR 
              LOGIN_URL=$(aws sts get-caller-identity --query Account --output text).dkr.ecr.$AWS_REGION.amazonaws.com
              AUTH_TOKEN=$(aws ecr get-login-password --region $AWS_REGION)
              sudo docker login --username AWS --password $AUTH_TOKEN $LOGIN_URL
              
              if [ $? -ne 0 ]; then
                exit 1
              fi
              
              # 3. Clone Repo and Deploy
              sudo -u ubuntu git clone "$GITHUB_REPO_URL" "$REPO_DIR" 
              cd "$REPO_DIR"
              sudo sh -c "$BUILD_CMD"
              EOF

  tags = {
    Name = "${var.app_name}-Server"
  }
}

# 5. OUTPUTS

# 5.1 Elastic IP (EIP)
resource "aws_eip" "app_ip" {
  instance = aws_instance.app_server.id
}

output "instance_ip" {
  description = "Public IP address."
  value       = aws_eip.app_ip.public_ip
}