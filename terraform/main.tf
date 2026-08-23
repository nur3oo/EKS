locals {
  lb_controller_namespace            = "kube-system"
  lb_controller_service_account_name = "aws-load-balancer-controller"
}

module "sg" {
  source   = "./sg"
  vpc_id   = module.vpc.vpc_id
  vpc_cidr = "10.0.0.0/16"
}

module "vpc" {
  source = "./vpc"
  region = var.region
}

module "eks" {
  source = "./eks"

  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  eks_cluster_sg_id  = module.sg.eks_cluster_sg_id
}

module "iam" {
  source = "./iam"

  oidc_issuer_url      = module.eks.cluster_oidc_issuer_url
  namespace            = local.lb_controller_namespace
  service_account_name = local.lb_controller_service_account_name
  eks_cluster_arn      = module.eks.cluster_arn
  cluster_name         = module.eks.cluster_name
}

module "certs" {
  source = "./certs"

  domain_name = var.domain_name
}

module "argocd" {
  source = "./argocd"

  depends_on = [module.eks]
}