variable "app_name" {
  description = "Name of the application, not containing spaces or special characters"
}
variable "environment" {
  description = "User-defined environment variable to ensure multiple copies of infrastucture may safely exist"
}
variable "aws_region" {
  description = "AWS Region for the infrastructure"
}
