module "networking" {
  source = "./networking"

  project_name        = var.project_name
  vpc_cidr            = var.vpc_cidr
  availability_zone   = var.availability_zone
  public_subnet_cidr  = "10.0.1.0/24"
  private_subnet_cidr = "10.0.2.0/24"
}

module "compute" {
  source = "./compute"

  project_name       = var.project_name
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids

  kubernetes_version      = var.kubernetes_version
  cpu_node_instance_types = var.cpu_node_instance_types
  cpu_node_min_size       = var.cpu_node_min_size
  cpu_node_max_size       = var.cpu_node_max_size
  cpu_node_desired_size   = var.cpu_node_desired_size
  cpu_node_disk_size      = var.cpu_node_disk_size
}
