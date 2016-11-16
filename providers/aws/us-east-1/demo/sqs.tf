resource "aws_sqs_queue" "git-commit-queue" {
  name = "${format("%s_%s", replace(var.project, "_", "-"), replace(var.environment, "_", "-"))}_GitCommitQueue"

  #message_retention_seconds = 86400

  #receive_wait_time_seconds = 10

  #redrive_policy = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.terraform_queue_deadletter.arn}\",\"maxReceiveCount\":4}"
}
