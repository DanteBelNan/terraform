module "ecr" {
  source   = "../../modules/ecr"
  app_name = var.app_name # Pasa la variable a este módulo
}

# 2. Definición del Servidor (EC2, EIP, SG)
module "compute_server" {
  source          = "../../modules/compute"
  app_name        = var.app_name
  instance_type   = var.instance_type
}