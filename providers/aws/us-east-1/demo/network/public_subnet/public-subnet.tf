resource "aws_internet_gateway" "public" {
  vpc_id = "${var.vpc_id}"

  tags {
    Name        = "${format("%s_%s_%s", replace(var.project, "_", "-"), replace(var.environment, "_", "-"), coalesce(replace(var.name, "_", "-"), var.name_default))}.public"
    Project     = "${var.project}"
    Environment = "${var.environment}"
    created_by  = "terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_subnet" "public" {
  vpc_id            = "${var.vpc_id}"
  cidr_block        = "${element(var.cidrs, count.index)}"
  availability_zone = "${element(var.azs, count.index)}"
  count             = "${length(var.cidrs)}"

  tags {
    Name        = "${format("%s_%s_%s", replace(var.project, "_", "-"), replace(var.environment, "_", "-"), coalesce(replace(var.name, "_", "-"), var.name_default))}.public"
    Project     = "${var.project}"
    Environment = "${var.environment}"
    created_by  = "terraform"
  }

  lifecycle {
    create_before_destroy = true
  }

  map_public_ip_on_launch = true
}

resource "aws_route_table" "public" {
  vpc_id = "${var.vpc_id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.public.id}"
  }

  tags {
    Name        = "${format("%s_%s_%s", replace(var.project, "_", "-"), replace(var.environment, "_", "-"), coalesce(replace(var.name, "_", "-"), var.name_default))}.public"
    Project     = "${var.project}"
    Environment = "${var.environment}"
    created_by  = "terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table_association" "public" {
  count          = "${length(var.cidrs)}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"

  lifecycle {
    create_before_destroy = true
  }
}
