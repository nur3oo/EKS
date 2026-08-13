variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-west-2"
}

variable "domain_name" {
  description = "Root domain (registered in Route53) used for the ALB's ACM certificate"
  type        = string
  default     = "nurtrade.net"
}

variable "repository_url" {
  description = "The repo url"
  type = string
  default = "nur/ecs"
  
}