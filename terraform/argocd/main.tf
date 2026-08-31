resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true
  timeout          = 600
}


resource "kubernetes_role" "gha_gitops_bootstrap" {
  metadata {
    name      = "gha-gitops-bootstrap"
    namespace = var.namespace
  }

  rule {
    api_groups = ["argoproj.io"]
    resources  = ["applications"]
    verbs      = ["get", "list", "watch", "create", "patch", "update", "delete"]
  }

  depends_on = [helm_release.argocd]
}

resource "kubernetes_role_binding" "gha_gitops_bootstrap" {
  metadata {
    name      = "gha-gitops-bootstrap"
    namespace = var.namespace
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.gha_gitops_bootstrap.metadata[0].name
  }

  subject {
    kind      = "Group"
    name      = "gha-gitops-bootstrap"
    api_group = "rbac.authorization.k8s.io"
  }
}
