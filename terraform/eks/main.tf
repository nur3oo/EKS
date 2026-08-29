# IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = "eks-cluster"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.34"

  vpc_config {
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
    endpoint_private_access = true
    endpoint_public_access  = true
    security_group_ids      = [var.eks_cluster_sg_id]
  }

  access_config {
    authentication_mode = "API"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]

  tags = {
    Name = "eks-cluster"
  }
}

# IAM Role for Node Group
resource "aws_iam_role" "eks_nodes" {
  name = "eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_ecr_read" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Managed Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "eks-node-group"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = ["t3.medium"]

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 3
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_ecr_read,
  ]

  tags = {
    Name = "eks-node-group"
  }
}

# cluster uses apii authentication mode (no aws-auth ConfigMap), so
# grants that identity admin access explicitly.
data "aws_caller_identity" "current" {}

# aws_caller_identity returns the STS assumed-role session ARN when run
# under a role (e.g. GitHub Actions OIDC), but EKS access entries need the
# underlying IAM role ARN - this resolves the session ARN back to it.
data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

resource "aws_eks_access_entry" "terraform_caller" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = data.aws_iam_session_context.current.issuer_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "terraform_caller_admin" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = data.aws_iam_session_context.current.issuer_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}
