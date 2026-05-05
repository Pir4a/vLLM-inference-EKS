module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.19"

  cluster_name    = var.project_name
  cluster_version = var.kubernetes_version

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  cluster_endpoint_public_access = true

  authentication_mode                      = "API_AND_CONFIG_MAP"
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    cpu = {
      instance_types = var.cpu_node_instance_types
      capacity_type  = "SPOT"
      min_size       = var.cpu_node_min_size
      max_size       = var.cpu_node_max_size
      desired_size   = var.cpu_node_desired_size
      disk_size      = var.cpu_node_disk_size
      labels = {
        workload = "platform"
      }
    }
  }
}
