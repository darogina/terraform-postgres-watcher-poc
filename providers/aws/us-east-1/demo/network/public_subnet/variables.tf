variable "project" {}

variable "environment" {}

variable "name" {
  default = ""
}

variable "name_default" {
  default = "default"
}

variable "vpc_id" {}

variable "cidrs" {
  type = "list"
}

variable "azs" {
  type = "list"
}
