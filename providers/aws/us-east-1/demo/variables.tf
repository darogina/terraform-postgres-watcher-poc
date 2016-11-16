# access_key and secret_key by default are read from '~/.aws/credentials'.  Do not check-in this file with keys hardcoded.

/*variable "access_key" {
  description = "AWS access key"
}

variable "secret_key" {
  description = "AWS secret access key"
}*/

variable "project" {}

variable "environment" {}

variable "region" {}

variable "amis" {
  default = {
    us-east-1 = "ami-f5f41398"
    us-west-1 = "ami-6e84fa0e"
    us-west-2 = "ami-d0f506b0"
  }
}

variable "azs" {
  type = "list"
}

/* VPC */
variable "vpc_cidr" {}

variable "private_subnets" {
  type = "list"
}

variable "public_subnets" {
  type = "list"
}

variable "vpc_enable_dns_hostnames" {
  default = ""
}

variable "vpc_enable_dns_support" {
  default = ""
}

/* Instances */
variable "ssh_public_key_path" {}

/* Git Watcher */
variable "watcher_ami_id" {
  default = ""
}

variable "watcher_tenancy" {}

variable "watcher_ebs_optimized" {}

variable "watcher_disable_api_termination" {}

variable "watcher_instance_type" {}

variable "watcher_enable_detailed_monitoring" {}

variable "watcher_associate_public_ip" {}

#variable "watcher_health_check_target" {}

variable "watcher_desired_instance_count" {}

variable "watcher_min_instance_count" {}

variable "watcher_max_instance_count" {}

variable "watcher_root_block_device_volume_type" {}

variable "watcher_root_block_device_volume_size" {}

variable "watcher_root_block_device_delete_on_termination" {}
