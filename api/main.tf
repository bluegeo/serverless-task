/*
Main API
*/
resource "aws_api_gateway_rest_api" "tasks" {
  name = "${var.app_name}-${var.environment}-tasks"
  description = "${var.app_name} ${var.environment} ${var.aws_region} Server Scaling API"
}

// Link with private VPC
resource "aws_api_gateway_vpc_link" "tasks" {
  name        = "${var.app_name}-${var.environment}-tasks"
  description = "API Gateway access to ECS tasks"
  target_arns = ["${var.load_balancer_arn}"]
}

/*
Auth
*/
resource "aws_api_gateway_authorizer" "api_auth" {
  name          = "${var.app_name}-${var.environment}-api-authorizer"
  type          = "COGNITO_USER_POOLS"
  rest_api_id   = "${aws_api_gateway_rest_api.tasks.id}"
  provider_arns = ["${var.user_pool_arn}"]

  depends_on = [
    "aws_api_gateway_rest_api.tasks"
  ]
}

/*
Resources
*/
// Main resource, which interpolates a username as a path
resource "aws_api_gateway_resource" "tasks" {
  depends_on = ["aws_api_gateway_rest_api.tasks"]

  rest_api_id = "${aws_api_gateway_rest_api.tasks.id}"
  parent_id = "${aws_api_gateway_rest_api.tasks.root_resource_id}"
  path_part = "{username}"
}

// Create separate resources for each task name
resource "aws_api_gateway_resource" "tasks_post" {
  depends_on = ["aws_api_gateway_resource.tasks"]

  count = "${length(var.task_names)}"

  rest_api_id = "${aws_api_gateway_rest_api.tasks.id}"
  parent_id = "${aws_api_gateway_resource.tasks.id}"
  path_part = "${var.task_names[count.index]}"
}

// Attach cors options to each resource
resource "aws_api_gateway_method" "tasks_cors" {
  count = "${length(var.task_names)}"

  rest_api_id   = "${aws_api_gateway_rest_api.tasks.id}"
  resource_id   = "${aws_api_gateway_resource.tasks_post.*.id[count.index]}"
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "tasks_cors" {
  count = "${length(var.task_names)}"

  depends_on = ["aws_api_gateway_method.tasks_cors"]

  rest_api_id   = "${aws_api_gateway_rest_api.tasks.id}"
  resource_id   = "${aws_api_gateway_resource.tasks_post.*.id[count.index]}"
  http_method = "${aws_api_gateway_method.tasks_cors.*.http_method[count.index]}"

  type = "MOCK"

  request_templates {
    "application/json" = "{ \"statusCode\": 200 }"
  }
}

resource "aws_api_gateway_integration_response" "tasks_cors" {
  depends_on = ["aws_api_gateway_integration.tasks_cors"]

  count = "${length(var.task_names)}"

  rest_api_id   = "${aws_api_gateway_rest_api.tasks.id}"
  resource_id   = "${aws_api_gateway_resource.tasks_post.*.id[count.index]}"
  http_method = "${aws_api_gateway_method.tasks_cors.*.http_method[count.index]}"
  status_code = 200

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers"     = "'${join(",", var.allowed_headers)}'"
    "method.response.header.Access-Control-Allow-Methods"     = "'${join(",", var.allowed_methods)}'"
    "method.response.header.Access-Control-Allow-Origin"      = "'${var.allowed_origin}'"
    "method.response.header.Access-Control-Allow-Credentials" = "'*'"
  }
}

resource "aws_api_gateway_method_response" "task_cors" {
  depends_on = ["aws_api_gateway_method.tasks_cors"]

  count = "${length(var.task_names)}"

  rest_api_id   = "${aws_api_gateway_rest_api.tasks.id}"
  resource_id   = "${aws_api_gateway_resource.tasks_post.*.id[count.index]}"
  http_method = "${aws_api_gateway_method.tasks_cors.*.http_method[count.index]}"
  status_code = 200

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers"     = true
    "method.response.header.Access-Control-Allow-Methods"     = true
    "method.response.header.Access-Control-Allow-Origin"      = true
    "method.response.header.Access-Control-Allow-Credentials" = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

// Method and integration with ECS
resource "aws_api_gateway_method" "tasks_post" {
  depends_on = [
    "aws_api_gateway_resource.tasks_post"
  ]

  count = "${length(var.task_names)}"

  rest_api_id   = "${aws_api_gateway_rest_api.tasks.id}"
  resource_id   = "${aws_api_gateway_resource.tasks_post.*.id[count.index]}"
  http_method = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = "${aws_api_gateway_authorizer.api_auth.id}"

  request_parameters = {
    "method.request.header.InvocationType" = true
  }
}

resource "aws_api_gateway_method_response" "tasks_response_200" {
  depends_on = ["aws_api_gateway_method.tasks_post"]

  count = "${length(var.task_names)}"

  rest_api_id   = "${aws_api_gateway_rest_api.tasks.id}"
  resource_id   = "${aws_api_gateway_resource.tasks_post.*.id[count.index]}"
  http_method   = "${aws_api_gateway_method.tasks_post.*.http_method[count.index]}"
  status_code   = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

// Integration with ECS
resource "aws_api_gateway_integration" "tasks_post" {
  depends_on = [
    "aws_api_gateway_method_response.tasks_response_200"
  ]

  count = "${length(var.task_names)}"

  rest_api_id   = "${aws_api_gateway_rest_api.tasks.id}"
  resource_id   = "${aws_api_gateway_resource.tasks_post.*.id[count.index]}"
  http_method = "${aws_api_gateway_method.tasks_post.*.http_method[count.index]}"

  integration_http_method = "POST"
  type                    = "HTTP_PROXY"
  passthrough_behavior    = "NEVER"

  connection_type = "VPC_LINK"
  connection_id   = "${aws_api_gateway_vpc_link.tasks.id}"
  uri = "http://${var.nlb_dns}:${var.container_ports[count.index]}/${var.task_names[count.index]}"

  // TODO
  request_templates = {

  }

  request_parameters = {
    "integration.request.header.X-Amz-Invocation-Type" = "'Event'"
  }

  credentials = "${var.tasks_api_arn}"
}

resource "aws_api_gateway_integration_response" "tasks_api_integration_response_200" {
  rest_api_id   = "${aws_api_gateway_rest_api.tasks.id}"
  resource_id   = "${aws_api_gateway_resource.tasks_post.id}"
  http_method = "${aws_api_gateway_method.tasks_post.http_method}"
  status_code = 200

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

  depends_on = [
    "aws_api_gateway_integration.tasks_post",
  ]
}

/*
Deploy the API
*/
resource "aws_api_gateway_deployment" "tasks" {
  depends_on = [
    "aws_api_gateway_integration_response.tasks_api_integration_response_200"
  ]
  description = "Run Task Deployment"

  rest_api_id = "${aws_api_gateway_rest_api.tasks.id}"
  stage_name  = "${var.app_name}-${var.environment}"
}

output "api_endpoint" {
  value = "${aws_api_gateway_deployment.tasks.invoke_url}"
}
