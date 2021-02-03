# -- root/networking/main.tf


module "networking" {
  source            = "./networking"
  vpc_cidr          = local.vpc_cidr
  access_ip         = var.access_ip
  security_groups   =  ""
  pub_subnet_count  = 4
  priv_subnet_count = 3
  max_subnets       = 20
  public_cidrs      = [for i in range(2, 255, 2) : cidrsubnet(local.vpc_cidr, 8, i)]
  private_cidrs     = [for i in range(1, 255, 2) : cidrsubnet(local.vpc_cidr, 8, i)]
}

