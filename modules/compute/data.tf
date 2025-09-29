data "local_file" "ssh_public_key" {
  filename = "/home/ubuntu/.ssh/id_rsa.pub"
}

# 2. Data Source para la AMI de Ubuntu más reciente
data "aws_ami" "ubuntu_latest" {
  # Solo buscamos la AMI que esté disponible y activa
  most_recent = true 

  # Filtros para Ubuntu 22.04 LTS (Jammy)
  filter {
    name   = "name"
    # El nombre de Canonical (Ubuntu) en us-east-2.
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  # El dueño de las AMIs oficiales de Ubuntu es Canonical
  owners = ["099720109477"] 
}
