resource "aws_security_group" "eks_cluster" {
  name        = "eks-cluster-sg"
  description = "EKS cluster control plane"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # AWS API calls (STS, EC2, etc.) made by the control plane itself.
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "eks-cluster-sg" }
}

resource "aws_security_group" "eks_nodes" {
  name        = "eks-nodes-sg"
  description = "EKS node group"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  ingress {
    from_port       = 1025
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
  }

  # Registries, AWS APIs, Helm repos, etc. - reached via NAT gateway.
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # DNS resolution (VPC resolver / CoreDNS), kept in-VPC only.
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = { Name = "eks-nodes-sg" }
}

# Control plane 2 node webhook/exec/logs calls kubelet,admission.
#  to the nodes 1025-65535 ingress rule above scoped to the nodes
# SG only, not to the internet.
resource "aws_security_group_rule" "cluster_to_nodes_webhooks" {
  type                     = "egress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_nodes.id
  description              = "control plane to node webhook/exec/logs"
}

