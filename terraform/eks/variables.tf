variable "private_subnet_ids" {
  description = "Private subnet IDs for the node group"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the cluster VPC config"
  type        = list(string)
}

variable "eks_cluster_sg_id" {
  description = "Security group ID for the EKS control plane"
  type        = string
}
