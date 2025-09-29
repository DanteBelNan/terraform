# environments/dev/main.tf

# 1. Definición del ECR
module "ecr" {
  source   = "../../../modules/ecr"
  app_name = var.app_name 
}

# 2. Definición del Servidor (EC2, EIP, SG)
module "compute_server" {
  source          = "../../../modules/compute"
  app_name        = var.app_name
  instance_type   = var.instance_type
}