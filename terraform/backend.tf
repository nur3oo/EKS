terraform {
  backend "s3" {
    bucket       = "nur-eks-terraform-state"
    key          = "eks/terraform.tfstate"
    region       = "eu-west-2"
    use_lockfile = true
  }
}