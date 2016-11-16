resource "aws_subnet" "private" {
  count = "${length(var.cidrs)}"

  vpc_id            = "${var.vpc_id}"
  cidr_block        = "${element(var.cidrs, count.index)}"
  availability_zone = "${element(var.azs, count.index)}"

  tags {
    Name        = "${format("%s_%s_%s", replace(var.project, "_", "-"), replace(var.environment, "_", "-"), coalesce(replace(var.name, "_", "-"), var.name_default))}.private"
    Project     = "${var.project}"
    Environment = "${var.environment}"
    created_by  = "terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table" "private" {
  count = "${signum(length(var.cidrs))}"

  vpc_id = "${var.vpc_id}"

  tags {
    Name        = "${format("%s_%s_%s", replace(var.project, "_", "-"), replace(var.environment, "_", "-"), coalesce(replace(var.name, "_", "-"), var.name_default))}.private"
    Project     = "${var.project}"
    Environment = "${var.environment}"
    created_by  = "terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table_association" "private" {
  count = "${length(var.cidrs)}"

  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${aws_route_table.private.id}"

  lifecycle {
    create_before_destroy = true
  }
}
