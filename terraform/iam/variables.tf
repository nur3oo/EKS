variable "oidc_issuer_url" {
  description = "EKS cluster OIDC issuer URL (module.eks.cluster_oidc_issuer_url)"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace of the aws-load-balancer-controller service account"
  type        = string
  default     = "kube-system"
}

variable "service_account_name" {
  description = "Kubernetes service account name used by the aws-load-balancer-controller"
  type        = string
  default     = "aws-load-balancer-controller"
}
