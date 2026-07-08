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
