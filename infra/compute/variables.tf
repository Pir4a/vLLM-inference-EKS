variable "project_name" {
  description = "Project identifier propagated as cluster name and tag prefix."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster lives. Provided by the networking module."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs hosting the EKS control plane ENIs and worker nodes."
  type        = list(string)
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version (e.g. 1.34)."
  type        = string
}

variable "cpu_node_instance_types" {
  description = "Instance types for the CPU node group. Multiple values enable Spot diversification."
  type        = list(string)
}

variable "cpu_node_min_size" {
  description = "Minimum size of the CPU node group. Keeps platform workloads always-on."
  type        = number
}

variable "cpu_node_max_size" {
  description = "Maximum size of the CPU node group. Headroom for platform pod growth."
  type        = number
}

variable "cpu_node_desired_size" {
  description = "Initial desired size of the CPU node group."
  type        = number
}

variable "cpu_node_disk_size" {
  description = "EBS root disk size (GB) per CPU node."
  type        = number
}
