output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.eks.arn
}

output "lb_controller_role_arn" {
  value = aws_iam_role.lb_controller.arn
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}

output "external_dns_role_arn" {
  value = aws_iam_role.external_dns.arn
}
