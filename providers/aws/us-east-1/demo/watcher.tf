# Upload watcher agent to S3
resource "aws_s3_bucket_object" "watcher-agent" {
  bucket = "${aws_s3_bucket.postgres-scripts.id}"
  key    = "git-watcher-agent.sh"
  source = "scripts/watcher/git-watcher-agent.sh"
  etag   = "${md5(file("scripts/watcher/git-watcher-agent.sh"))}"
}

# Systemd service for the watcher agent
data "template_file" "git-watcher-agent-service-template" {
  template = "${file("${path.module}/scripts/watcher/git-watcher-agent.service.tpl")}"

  vars {
    agent_key = "${aws_s3_bucket_object.watcher-agent.id}"
    sqs_url   = "${aws_sqs_queue.git-commit-queue.id}"
  }
}

# Upload Systemd service to S3
resource "aws_s3_bucket_object" "watcher-agent-service" {
  bucket  = "${aws_s3_bucket.postgres-scripts.id}"
  key     = "git-watcher-agent.service"
  content = "${data.template_file.git-watcher-agent-service-template.rendered}"
}

# Create an Instance Profile so that the Git Watcher EC2 instances can communicate with SQS
resource "aws_iam_instance_profile" "watcher-instance-profile" {
  name       = "${format("%s_%s", replace(var.project, "_", "-"), replace(var.environment, "_", "-"))}_PgGitWatcher_InstanceProfile"
  roles      = ["${aws_iam_role.postgres-builder-role.name}"]
  depends_on = ["aws_iam_role.postgres-builder-role"]

  lifecycle {
    create_before_destroy = true
  }

  provisioner "local-exec" {
    command = "sleep 10"
  }
}

# Bootstrap script for watcher agent instance
data "template_file" "watcher-bootstrap-template" {
  template = "${file("${path.module}/scripts/watcher/git-watcher-bootstrap.tpl")}"

  vars {
    bucket_name = "${aws_s3_bucket.postgres-scripts.id}"
    agent_key   = "${aws_s3_bucket_object.watcher-agent.id}"
    service_key = "${aws_s3_bucket_object.watcher-agent-service.id}"
    sqs_url     = "${aws_sqs_queue.git-commit-queue.id}"
  }
}

# Combine global bootstrap and watcher agent bootstrap scripts
data "template_cloudinit_config" "watcher-cloudinit-config" {
  gzip          = true
  base64_encode = false

  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.bootstrap-template.rendered}"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.watcher-bootstrap-template.rendered}"
  }
}

# Launch Configuration for watcher agent instance
resource "aws_launch_configuration" "watcher-launch-configuration" {
  name_prefix                 = "${format("%s_%s", replace(var.project, "_", "-"), replace(var.environment, "_", "-"))}_GitWatcher"
  image_id                    = "${var.watcher_ami_id}"
  instance_type               = "${var.watcher_instance_type}"
  associate_public_ip_address = "${var.watcher_associate_public_ip}"
  key_name                    = "${aws_key_pair.ssh_key.key_name}"

  security_groups = ["${aws_security_group.default.id}"]

  iam_instance_profile = "${aws_iam_instance_profile.watcher-instance-profile.name}"
  user_data            = "${data.template_cloudinit_config.watcher-cloudinit-config.rendered}"

  root_block_device {
    volume_type           = "${var.watcher_root_block_device_volume_type}"
    volume_size           = "${var.watcher_root_block_device_volume_size}"
    delete_on_termination = "${var.watcher_root_block_device_delete_on_termination}"
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = ["aws_iam_instance_profile.watcher-instance-profile"]
}

# Auto Scaling Group for watcher agent instances 
resource "aws_autoscaling_group" "watcher-asg" {
  name                = "${format("%s_%s", replace(var.project, "_", "-"), replace(var.environment, "_", "-"))}_GitWatcher"
  vpc_zone_identifier = ["${module.network.public_subnet_ids}"]
  max_size            = "${var.watcher_max_instance_count}"
  min_size            = "${var.watcher_min_instance_count}"

  #health_check_grace_period = "${var.watcher_health_check_grace_period}"
  #health_check_type         = "${var.watcher_health_check_type}"
  desired_capacity = "${var.watcher_desired_instance_count}"

  force_delete         = false
  launch_configuration = "${aws_launch_configuration.watcher-launch-configuration.name}"

  tag {
    key                 = "Name"
    value               = "${format("%s_%s", replace(var.project, "_", "-"), replace(var.environment, "_", "-"))}_GitWatcher"
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
