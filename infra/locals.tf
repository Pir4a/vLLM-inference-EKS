locals {
  common_tags = {

    Project     = var.project_name
    ManagedBy   = "Terraform"
    Environment = "portfolio"
    Owner       = "stephane / Pir4a"

  }
}
