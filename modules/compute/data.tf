# 1. Data Source for Local SSH Public Key (Optional: for adding to instance)
data "local_file" "ssh_public_key" {
  filename = "/home/ubuntu/.ssh/id_rsa.pub"
}

# 2. Data Source for the Latest Ubuntu AMI
data "aws_ami" "ubuntu_latest" {
  # Only search for the latest available AMI
  most_recent = true 

  # Filters for Ubuntu 22.04 LTS (Jammy)
  filter {
    name   = "name"
    # Canonical's name in us-east-2.
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  # Owner ID for official Ubuntu AMIs (Canonical)
  owners = ["099720109477"] 
}