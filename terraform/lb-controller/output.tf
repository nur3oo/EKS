output "release_name" {
  value = helm_release.aws_load_balancer_controller.name
}

output "release_status" {
  value = helm_release.aws_load_balancer_controller.status
}
