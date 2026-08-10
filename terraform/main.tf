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
}

module "lb_controller" {
  source = "./lb-controller"

  cluster_name         = module.eks.cluster_name
  region               = var.region
  vpc_id               = module.vpc.vpc_id
  namespace            = local.lb_controller_namespace
  service_account_name = local.lb_controller_service_account_name
  role_arn             = module.iam.lb_controller_role_arn

  depends_on = [module.eks]
}

module "alb" {
  source = "./alb"

  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id         = module.sg.alb_sg_id
  domain_name       = var.domain_name

  depends_on = [module.vpc, module.sg]
}
