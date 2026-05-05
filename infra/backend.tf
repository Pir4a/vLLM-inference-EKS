terraform {
  backend "s3" {
    bucket       = "780138805035-tfstate-llm-inference-sre"
    key          = "infra/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }

}
