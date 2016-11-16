provider "aws" {
  # For different ways to provide authentication credentials see https://www.terraform.io/docs/providers/aws/#authentication

  # By default this is reading from your shared credentials file '~/.aws/credentials'

  # access_key = "${var.access_key}"

  # secret_key = "${var.secret_key}"

  # Read credentials from profile defined in '~/.aws.credentials'
  profile = "rogina"
  region  = "${var.region}"
}

resource "aws_key_pair" "ssh_key" {
  key_name   = "${var.project}-${var.environment}"
  public_key = "${file(var.ssh_public_key_path)}"

  lifecycle {
    create_before_destroy = true
  }
}

data "template_file" "bootstrap-template" {
  template = "${file("${path.module}/scripts/bootstrap.tpl")}"

  vars {
    region = "${var.region}"
  }
}
