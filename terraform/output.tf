output "cert_arn" {
  value = module.alb.cert_arn
}

output "alb_sg_id" {
  value = module.sg.alb_sg_id
}
