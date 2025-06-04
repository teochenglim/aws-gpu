variable "region" {
  description = "AWS region"
  type        = string
}

variable "aws_sso_profile" {
  description = "AWS SSO profile name"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "public_subnet" {
  description = "Public subnet CIDR"
  type        = string
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "spot_max_price" {
  description = "Spot instance max price"
  type        = string
}