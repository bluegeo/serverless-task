/*
Main API
*/
//resource "aws_api_gateway_rest_api" "tasks" {
//  name = "${var.app_name}-${var.environment}-tasks"
//}
//
///*
//Resources
//*/
//resource "aws_api_gateway_resource" "tasks_post" {
//  parent_id = aws_api_gateway_rest_api.tasks.id
//  path_part = "{username}"
//  rest_api_id = aws_api_gateway_rest_api.tasks.id
//}
//
//module "cors" {
//  source = "CORS"
//  rest_api_id = ""
//  resource_id = ""
//  allowed_headers = ""
//  allowed_methods = ""
//  allowed_origin = ""
//}
