module "network" {
  source = "./network"

  project                  = "${var.project}"
  environment              = "${var.environment}"
  vpc_cidr                 = "${var.vpc_cidr}"
  azs                      = "${var.azs}"
  public_subnet_cidrs      = "${var.public_subnets}"
  private_subnet_cidrs     = "${var.private_subnets}"
  vpc_enable_dns_hostnames = "${var.vpc_enable_dns_hostnames}"
  vpc_enable_dns_support   = "${var.vpc_enable_dns_support}"
}
