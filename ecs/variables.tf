variable "app_name" {
  description = "Name of the application, not containing spaces or special characters"
}
variable "environment" {
  description = "User-defined environment variable to ensure multiple copies of infrastucture may safely exist"
}
variable "aws_region" {
  description = "AWS Region for the infrastructure"
}
variable "vpc_cidr" {
  description = "The CIDR block for the VPC that hosts the resources"
  default = "10.0.0.0/16"
}
variable "az_count" {
  description = "Number of availability zones for the private subnet. Note, at least 2 are required for the ALB"
  default = 2
}
variable "task_role_arn" {
  description = "IAM role for the docker containers"
}
variable "ecr_repo_name" {
  description = "Name of the repository used to store docker images"
}
variable "profile" {
  description = "AWS CLI profile"
}

/*
Task Definitions

These are manually created .json documents in the task-definitions folder which provide logic to ECS when starting
containers from docker images.
*/
variable "task_names" {
  description = "Names of the task file that match those in the task-definitions directory (must be exact matches)"
  type = "list"
  default = ["tasks"]
}
variable "container_ports" {
  description = "Each container is connected to the NLB through an individual port"
  type = "list"
  default = [80]
}
variable "cpu" {
  description = "Fargate requires the CPU resources to be defined at the task level. These are ordered by names."
  type = "list"
  default = ["512"]  // 1024 === 1 vCPU
}
variable "memory" {
  description = "Fargate requires the Memory resources to be defined at the task level. These are ordered by names."
  type = "list"
  default = ["1024"]  // See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html
}
