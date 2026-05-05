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
