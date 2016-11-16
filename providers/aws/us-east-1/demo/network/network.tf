module "vpc" {
  source = "./vpc"

  project              = "${var.project}"
  environment          = "${var.environment}"
  name                 = "${var.name}"
  cidr                 = "${var.vpc_cidr}"
  enable_dns_support   = "${var.vpc_enable_dns_support}"
  enable_dns_hostnames = "${var.vpc_enable_dns_hostnames}"
}

module "public_subnet" {
  source = "./public_subnet"

  project     = "${var.project}"
  environment = "${var.environment}"
  name        = "${var.name}"
  vpc_id      = "${module.vpc.id}"
  cidrs       = "${var.public_subnet_cidrs}"
  azs         = "${var.azs}"
}

module "private_subnet" {
  source = "./private_subnet"

  project     = "${var.project}"
  environment = "${var.environment}"
  name        = "${var.name}"
  vpc_id      = "${module.vpc.id}"
  cidrs       = "${var.private_subnet_cidrs}"
  azs         = "${var.azs}"
}
