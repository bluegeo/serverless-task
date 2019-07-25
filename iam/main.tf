/*
Identity
*/
data "aws_caller_identity" "current" {}

/*
=========
ECS Roles
=========
*/
/*
Role that all tasks (docker containers) assume
*/
data "aws_iam_policy_document" "tasks" {
  statement {
    effect = "Allow",
    actions   = [
      "s3:*"
    ]
    resources = [
      "arn:aws:s3:::${var.service_bucket_name}/*"
    ]
  }
}

resource "aws_iam_policy" "tasks" {
  name   = "${var.app_name}-${var.environment}-tasks"
  description = "Allow ECS containers to assume roles"
  path   = "/"
  policy = "${data.aws_iam_policy_document.tasks.json}"
}

resource "aws_iam_role" "tasks" {
  name = "${var.app_name}-${var.environment}-tasks"
  description = "Allow ECS containers to assume roles"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "tasks" {
  depends_on = ["aws_iam_policy.tasks", "aws_iam_role.tasks"]

  role       = "${aws_iam_role.tasks.name}"
  policy_arn = "${aws_iam_policy.tasks.arn}"
}

output "task_role_arn" {
  value = "${aws_iam_role.tasks.arn}"
}

/*
API Gateway - Allow API Gateway to access the Network ELB
*/
data "aws_iam_policy_document" "tasks_api" {
  statement {
    effect = "Allow",
    actions   = [
      "ecs:RunTask"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "tasks_api" {
  name   = "${var.app_name}-${var.environment}-tasks-api"
  description = "Allow API Gateway to run tasks"
  path   = "/"
  policy = "${data.aws_iam_policy_document.tasks_api.json}"
}

resource "aws_iam_role" "tasks_api" {
  name = "${var.app_name}-${var.environment}-tasks-api"
  description = "Allow API Gateway to run tasks"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "tasks_api" {
  depends_on = ["aws_iam_policy.tasks_api", "aws_iam_role.tasks_api"]

  role       = "${aws_iam_role.tasks_api.name}"
  policy_arn = "${aws_iam_policy.tasks_api.arn}"
}

output "tasks_api_arn" {
  value = "${aws_iam_role.tasks_api.arn}"
}
