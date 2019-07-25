variable "app_name" {
  description = "Name of the application, not containing spaces or special characters"
}
variable "environment" {
  description = "User-defined environment variable to ensure multiple copies of infrastucture may safely exist"
}
variable "aws_region" {
  description = "AWS Region for the infrastructure"
}
variable "user_pool_arn" {
  description = "The user pool used for API Gateway authentication"
}
variable "allowed_headers" {
  description = "Allowed headers for API Gateway calls"
  type        = "list"

  default = [
    "Content-Type",
    "X-Amz-Date",
    "Authorization",
    "X-Api-Key",
    "X-Amz-Security-Token",
  ]
}
variable "allowed_methods" {
  description = "Allowed methods for API Gateway calls"
  type        = "list"

  default = [
    "POST"
  ]
}
variable "allowed_origin" {
  description = "Allowed origin for API Gateway calls"
  type        = "string"
  default     = "*"
}
variable "task_names" {
  description = "Names of the tasks for the API ECS integration"
  type = "list"
}
variable "tasks_api_arn" {
  description = "The arn of the IAM Role API Gateway assumes to run ECS tasks"
}
variable "load_balancer_arn" {
  description = "Netowrk Load balancer ARN"
}
variable "nlb_dns" {
  description = "DNS of the load balancer"
}
variable "container_ports" {
  description = "Ports of the app to prepare endpoint paths"
  type = "list"
}
