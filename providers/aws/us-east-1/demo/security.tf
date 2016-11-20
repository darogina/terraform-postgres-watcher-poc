resource "aws_iam_role" "postgres-builder-role" {
  name = "${format("%s_%s", replace(var.project, "_", "-"), replace(var.environment, "_", "-"))}_PostgresBuilder_InstanceRole"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "sts:AssumeRole"
      ],
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com"
        ]
      }
    }
  ]
}
EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy" "sqs-fullaccess-policy" {
  name = "PostgresBuilderSQSFullAccess"
  role = "${aws_iam_role.postgres-builder-role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "sqs:*",
        "s3:Get*",
        "s3:List*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "default" {
  name_prefix = "${format("%s_%s", replace(var.project, "_", "-"), replace(var.environment, "_", "-"))}_"
  description = "Security group for the Postgres build system"
  vpc_id      = "${module.network.vpc_id}"

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.ssh_cidrs}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name        = "${format("%s_%s_%s", replace(var.project, "_", "-"), replace(var.environment, "_", "-"))}"
    Project     = "${var.project}"
    Environment = "${var.environment}"
    created_by  = "terraform"
  }
}
