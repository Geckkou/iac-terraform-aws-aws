terraform {
  backend "s3" {
    bucket       = "vtg-alexandre-terraform-state"
    key          = "eks-github-actions-prod/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}
