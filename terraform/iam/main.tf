data "tls_certificate" "eks" {
  url = var.oidc_issuer_url
}

resource "aws_iam_openid_connect_provider" "eks" {
  url             = var.oidc_issuer_url
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
}

locals {
  oidc_provider_host = replace(var.oidc_issuer_url, "https://", "")
}

resource "aws_iam_role" "lb_controller" {
  name = "aws-load-balancer-controller-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRoleWithWebIdentity"
      Principal = { Federated = aws_iam_openid_connect_provider.eks.arn }
      Condition = {
        StringEquals = {
          "${local.oidc_provider_host}:sub" = "system:serviceaccount:${var.namespace}:${var.service_account_name}"
          "${local.oidc_provider_host}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_policy" "lb_controller" {
  name   = "AWSLoadBalancerControllerIAMPolicy"
  policy = file("${path.module}/policies/aws-load-balancer-controller-iam-policy.json")
}

resource "aws_iam_role_policy_attachment" "lb_controller" {
  role       = aws_iam_role.lb_controller.name
  policy_arn = aws_iam_policy.lb_controller.arn
}

# GitHub Actions OIDC - the provider is account-wide (identical for every
# repo; per-repo scoping happens in the role's trust policy below), so it's
# looked up rather than created to avoid clashing with one that may already
# exist in this account from something else.
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_role" "github_actions" {
  name = "github-action"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRoleWithWebIdentity"
      Principal = { Federated = data.aws_iam_openid_connect_provider.github.arn }
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:ref:refs/heads/main"
        }
      }
    }]
  })
}

# Just enough to look up cluster connection info - actual permission to
# touch anything in the cluster comes from Kubernetes RBAC, not IAM.
resource "aws_iam_policy" "github_actions_eks_describe" {
  name = "github-actions-eks-describe"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "eks:DescribeCluster"
      Resource = var.eks_cluster_arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_eks_describe" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_eks_describe.arn
}

# Lets the github_actions role authenticate to the cluster's Kubernetes API.
# What it's actually allowed to do once authenticated is controlled by the
# gha-gitops-bootstrap Role/RoleBinding in the argocd module, not here.
resource "aws_eks_access_entry" "github_actions" {
  cluster_name      = var.cluster_name
  principal_arn     = aws_iam_role.github_actions.arn
  kubernetes_groups = ["gha-gitops-bootstrap"]
  type              = "STANDARD"
}
