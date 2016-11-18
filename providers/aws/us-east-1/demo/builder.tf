# Upload builder agent to S3
resource "aws_s3_bucket_object" "builder-agent" {
  bucket = "${aws_s3_bucket.postgres-scripts.id}"
  key    = "pg-builder-agent.sh"
  source = "scripts/builder/pg-builder-agent.sh"
  etag   = "${md5(file("scripts/builder/pg-builder-agent.sh"))}"
}

# Systemd service for the builder agent
data "template_file" "pg-builder-agent-service-template" {
  template = "${file("${path.module}/scripts/builder/pg-builder-agent.service.tpl")}"

  vars {
    working_dir = "/opt/pg-builder"
    agent_key   = "${aws_s3_bucket_object.builder-agent.id}"
    sqs_url     = "${aws_sqs_queue.git-commit-queue.id}"
    log_file    = "/var/log/pg-builder-agent.log"
  }
}

# Upload Systemd service to S3
resource "aws_s3_bucket_object" "builder-agent-service" {
  bucket  = "${aws_s3_bucket.postgres-scripts.id}"
  key     = "pg-builder-agent.service"
  content = "${data.template_file.pg-builder-agent-service-template.rendered}"
}

# Create an Instance Profile so that the PG Builder EC2 instances can communicate with SQS
resource "aws_iam_instance_profile" "builder-instance-profile" {
  name       = "${format("%s_%s", replace(var.project, "_", "-"), replace(var.environment, "_", "-"))}_PgBuilder_InstanceProfile"
  roles      = ["${aws_iam_role.postgres-builder-role.name}"]
  depends_on = ["aws_iam_role.postgres-builder-role"]

  lifecycle {
    create_before_destroy = true
  }

  provisioner "local-exec" {
    command = "sleep 10"
  }
}

# Bootstrap script for builder agent instance
data "template_file" "builder-bootstrap-template" {
  template = "${file("${path.module}/scripts/builder/pg-builder-bootstrap.tpl")}"

  vars {
    bucket_name = "${aws_s3_bucket.postgres-scripts.id}"
    region      = "${var.region}"
    agent_key   = "${aws_s3_bucket_object.builder-agent.id}"
    working_dir = "/opt/pg-builder"
    service_key = "${aws_s3_bucket_object.builder-agent-service.id}"
    sqs_url     = "${aws_sqs_queue.git-commit-queue.id}"
    log_file    = "/var/log/pg-builder-agent.log"
  }
}

# Combine global bootstrap and builder agent bootstrap scripts
data "template_cloudinit_config" "builder-cloudinit-config" {
  gzip          = true
  base64_encode = false

  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.bootstrap-template.rendered}"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.builder-bootstrap-template.rendered}"
  }
}

# Launch Configuration for builder agent instance
resource "aws_launch_configuration" "builder-launch-configuration" {
  name_prefix                 = "${format("%s_%s", replace(var.project, "_", "-"), replace(var.environment, "_", "-"))}_PgBuilder"
  image_id                    = "${var.builder_ami_id}"
  instance_type               = "${var.builder_instance_type}"
  associate_public_ip_address = "${var.builder_associate_public_ip}"
  key_name                    = "${aws_key_pair.ssh_key.key_name}"

  #security_groups             = ["${var.security_group_ids}"]

  iam_instance_profile = "${aws_iam_instance_profile.builder-instance-profile.name}"
  user_data            = "${data.template_cloudinit_config.builder-cloudinit-config.rendered}"
  root_block_device {
    volume_type           = "${var.builder_root_block_device_volume_type}"
    volume_size           = "${var.builder_root_block_device_volume_size}"
    delete_on_termination = "${var.builder_root_block_device_delete_on_termination}"
  }
  lifecycle {
    create_before_destroy = true
  }
  depends_on = ["aws_iam_instance_profile.builder-instance-profile"]
}

# Auto Scaling Group for builder agent instances
resource "aws_autoscaling_group" "builder-asg" {
  name                = "${format("%s_%s", replace(var.project, "_", "-"), replace(var.environment, "_", "-"))}_PgBuilder"
  vpc_zone_identifier = ["${module.network.public_subnet_ids}"]
  max_size            = "${var.builder_max_instance_count}"
  min_size            = "${var.builder_min_instance_count}"

  desired_capacity = "${var.builder_desired_instance_count}"

  force_delete         = false
  launch_configuration = "${aws_launch_configuration.builder-launch-configuration.name}"

  tag {
    key                 = "Name"
    value               = "${format("%s_%s", replace(var.project, "_", "-"), replace(var.environment, "_", "-"))}_PgBuilder"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "${var.project}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "${var.environment}"
    propagate_at_launch = true
  }

  tag {
    key                 = "created_by"
    value               = "terraform"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
