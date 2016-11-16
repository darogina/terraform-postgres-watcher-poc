resource "aws_s3_bucket" "postgres-scripts" {
  bucket = "${format("%s_%s", replace(var.project, "_", "-"), replace(var.environment, "_", "-"))}_scripts"
  acl    = "private"

  tags {
    Name        = "${format("%s_%s", replace(var.project, "_", "-"), replace(var.environment, "_", "-"))}_scripts"
    Project     = "${var.project}"
    Environment = "${var.environment}"
    created_by  = "terraform"
  }
}
