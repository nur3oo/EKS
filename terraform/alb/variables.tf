variable "vpc_id" {
    type = string
  
}

variable "port" {
    type = string
    default = "3001"
  
}

variable "health_check_path" {
    type = string
    default = "/"
  
}

variable "matcher" {
    type = string
    default = "200-399"
  
}

variable "public_subnet_ids" {
    type = string
  
}

variable "alb_sg_id" {
    type = string
  
}