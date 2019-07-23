variable "app_name" {
  description = "Name of the application, not containing spaces or special characters"
}
variable "environment" {
  description = "User-defined environment variable to ensure multiple copies of infrastucture may safely exist"
}
variable "aws_region" {
  description = "AWS Region for the infrastructure"
}

variable "minimum_length" {
  description = "User Pool Configuration"
  default = 6
}
variable "require_lowercase" {
  description = "User Pool Configuration"
  default = false
}
variable "require_numbers" {
  description = "User Pool Configuration"
  default = false
}
variable "require_symbols" {
  description = "User Pool Configuration"
  default = false
}
variable "require_uppercase" {
  description = "User Pool Configuration"
  default = false
}
