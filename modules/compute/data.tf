# 1. Data Source for Local SSH Public Key
data "local_file" "ssh_public_key" {
  filename = "/home/ubuntu/.ssh/id_rsa.pub"
}

# 2. Data Source for the Latest Ubuntu AMI
data "aws_ami" "ubuntu_latest" {
  most_recent = true 

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] 
}