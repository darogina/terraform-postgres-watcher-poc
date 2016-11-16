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
