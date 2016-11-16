variable "project" {}

variable "environment" {}

variable "name" {
  default = ""
}

variable "vpc_cidr" {}

variable "azs" {
  type = "list"
}

variable "private_subnet_cidrs" {
  type = "list"
}

variable "public_subnet_cidrs" {
  type = "list"
}

variable "vpc_enable_dns_hostnames" {}

variable "vpc_enable_dns_support" {}
