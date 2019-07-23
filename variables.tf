// Populated from a terraform.tfvars file
variable "app_name" {
  description = "Name of the application, not containing spaces or special characters"
}
variable "environment" {
  description = "User-defined environment variable to ensure multiple copies of infrastucture may safely exist"
}
variable "aws_region" {
  description = "AWS Region for the infrastructure"
}
variable "profile" {
  description = "AWS CLI profile- usually 'default', unless multiple IAM roles are needed"
}
variable "service_bucket_name" {
  description = "Name of the bucket to store data used and created by services"
}
variable "ecr_repo_name" {
  description = "Name of the ECR repository to store docker images"
  default = "serverless-task-repo"
}
