#remote backend -- Is necessary create to bucket previous
terraform {
  backend "s3" {
    bucket       = "vtg-alexandre-terraform-state"
    key          = "eks-github-actions/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true # Enable the Lockfile configuration on the S3 Bucket
  }
}