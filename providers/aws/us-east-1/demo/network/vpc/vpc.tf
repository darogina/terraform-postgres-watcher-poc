resource "aws_vpc" "vpc" {
  cidr_block           = "${var.cidr}"
  enable_dns_support   = "${coalesce(var.enable_dns_support, var.enable_dns_support_default)}"
  enable_dns_hostnames = "${coalesce(var.enable_dns_hostnames, var.enable_dns_hostnames_default)}"
  instance_tenancy     = "${var.instance_tenancy}"

  tags {
    Name        = "${format("%s_%s_%s", replace(var.project, "_", "-"), replace(var.environment, "_", "-"), coalesce(replace(var.name, "_", "-"), var.name_default))}"
    Project     = "${var.project}"
    Environment = "${var.environment}"
    created_by  = "terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}
