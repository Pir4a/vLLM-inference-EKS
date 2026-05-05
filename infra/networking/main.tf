module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.21"
  name    = var.project_name
  cidr    = var.vpc_cidr

  azs             = [var.availability_zone]
  private_subnets = [var.private_subnet_cidr]
  public_subnets  = [var.public_subnet_cidr]

  single_nat_gateway   = true
  enable_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

}
