variable "project" {}

variable "environment" {}

variable "name" {
  default = ""
}

variable "name_default" {
  default = "default"
}

variable "cidr" {}

variable "enable_dns_hostnames" {
  default = ""
}

variable "enable_dns_hostnames_default" {
  description = "should be true if you want to use private DNS within the VPC"
  default     = false
}

variable "enable_dns_support" {
  default = ""
}

variable "enable_dns_support_default" {
  description = "should be true if you want to use private DNS within the VPC"
  default     = false
}

variable "instance_tenancy" {
  default = "default"
}
