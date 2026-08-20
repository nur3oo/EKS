variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "region" {
  description = "AWS region the cluster runs in"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID the cluster runs in"
  type        = string
}

variable "namespace" {
  description = "Namespace to install the controller into"
  type        = string
  default     = "kube-system"
}

variable "service_account_name" {
  description = "Name of the Kubernetes service account (must match the IRSA trust policy's :sub)"
  type        = string
  default     = "aws-load-balancer-controller"
}

variable "role_arn" {
  description = "IRSA IAM role ARN to annotate onto the controller's service account"
  type        = string
}

variable "chart_version" {
  description = "aws-load-balancer-controller Helm chart version - keep in lockstep with the pinned IAM policy JSON's release tag"
  type        = string
  default     = "3.4.1"
}

