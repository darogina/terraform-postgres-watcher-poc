# VPC
output "vpc_id" {
  value = "${module.vpc.id}"
}

output "vpc_cidr" {
  value = "${module.vpc.cidr}"
}

# Subnets
output "public_subnet_ids" {
  value = ["${module.public_subnet.subnet_ids}"]
}

output "private_subnet_ids" {
  value = ["${module.private_subnet.subnet_ids}"]
}
