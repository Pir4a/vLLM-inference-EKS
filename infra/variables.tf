variable "region" {
  description = "AWS region for all resources. See ADR-004 (cost + spot pool size in us-east-1)."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project identifier. Used as prefix for resource names and propagated as the `Project` tag for cost tracking via AWS Cost Explorer."
  type        = string
  default     = "llm-inference-sre"
}

variable "vpc_cidr" {
  description = "VPC CIDR block (RFC 1918). Split into one public /24 and one private /24 in a single AZ."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zone" {
  description = "Single AZ where all subnets and workloads live. See ADR-006 — multi-AZ is demonstrated in a separate portfolio project."
  type        = string
  default     = "us-east-1a"
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version. Pinned to N-1 for stability."
  type        = string
  default     = "1.32"
}

variable "cpu_node_instance_types" {
  description = "Instance types for the CPU node group (Spot)."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "cpu_node_min_size" {
  description = "Minimum CPU node count. Always-on node group for platform workloads."
  type        = number
  default     = 1
}

variable "cpu_node_max_size" {
  description = "Maximum CPU node count. Headroom for platform pod growth."
  type        = number
  default     = 2
}

variable "cpu_node_desired_size" {
  description = "Initial CPU node count."
  type        = number
  default     = 1
}

variable "cpu_node_disk_size" {
  description = "EBS root disk size (GB) per CPU node. 30 GB covers platform workloads (Prometheus, Grafana, rag-api, vector-db) with margin."
  type        = number
  default     = 30
}
