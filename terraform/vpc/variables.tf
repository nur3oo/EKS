variable "region" {
  description = "aws region to deploy into"
  type        = string
  default     = "eu-west-2"
}

variable "public_subnet_cidrs" {
  description = "cidr blocks for public subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "private_subnet_cidrs" {
  description = "cidr blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "endpoint_sg" {
  description = "security group id for vpc endpoints"
  type        = string
}