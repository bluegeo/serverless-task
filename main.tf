/*
=============
Configuration
=============
*/
provider "aws" {
  shared_credentials_file = "$HOME/.aws/credentials"
  profile                 = "${var.profile}"
  region                  = "${var.aws_region}"
}

/*
=========================
Identity & Authentication
=========================
*/
module "authentication" {
  source = "authentication"
  app_name = "${var.app_name}"
  environment = "${var.environment}"
  aws_region = "${var.aws_region}"
}

module "iam" {
  source = "iam"
  app_name = "${var.app_name}"
  environment = "${var.environment}"
  aws_region = "${var.aws_region}"
  service_bucket_name = "${var.service_bucket_name}"
}

/*
===
ECS
===
*/
module "ecs" {
  source = "ecs"
  app_name = "${var.app_name}"
  environment = "${var.environment}"
  aws_region = "${var.aws_region}"
  task_role_arn = "${module.iam.task_role_arn}"
  ecr_repo_name = "${var.ecr_repo_name}"
  profile = "${var.profile}"
}

/*
===
API
===
*/
module "api" {
  source = "api"
  app_name = "${var.app_name}"
  environment = "${var.environment}"
  aws_region = "${var.aws_region}"
}

/*
=======
Storage
=======
*/
module "storage" {
  source = "storage"
  service_bucket_name = "${var.service_bucket_name}"
  app_name = "${var.app_name}"
  environment = "${var.environment}"
}

/*
======
Output
======
*/
//data template_file "aws_exports" {
//  template = "${file("${path.root}/aws_template.js")}"
//
//  vars = {
//    // Auth
//    "aws_region" = "${var.aws_region}"
//    "user_pool_id" = "${module.authentication.user_pool_id}"
//    "user_pool_client_id" = "${module.authentication.user_pool_client_id}"
//
//    // API
//    "api_endpoint" = "${module.api.endpoint}"
//  }
//}
//
//resource "local_file" "aws_exports" {
//  content = "${data.template_file.aws_exports.rendered}"
//  filename = "${path.root}/aws-exports.js"
//}
