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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "eks-nodes-sg" }
}

resource "aws_security_group" "alb" {
  name        = "eks-alb-sg"
  description = "Internet-facing ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "eks-alb-sg" }
}

locals {
  alb_node_ports = {
    uptime_kuma = 3001
    grafana     = 3000
    prometheus  = 9090
  }
}

resource "aws_security_group_rule" "alb_to_nodes" {
  for_each = local.alb_node_ports

  type                     = "egress"
  from_port                = each.value
  to_port                  = each.value
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb.id
  source_security_group_id = aws_security_group.eks_nodes.id
  description              = each.key
}

resource "aws_security_group_rule" "nodes_from_alb" {
  for_each = local.alb_node_ports

  type                     = "ingress"
  from_port                = each.value
  to_port                  = each.value
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.alb.id
  description              = each.key
}
