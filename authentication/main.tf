/*
Authentication module to integrate API calls with a cognito user pool to manage security of ECS calls
*/
resource "aws_cognito_user_pool" "pool" {
  name =  "${var.app_name}-${var.environment}-user-pool"

  password_policy {
    minimum_length    = "${var.minimum_length}"
    require_lowercase = "${var.require_lowercase}"
    require_numbers   = "${var.require_numbers}"
    require_symbols   = "${var.require_symbols}"
    require_uppercase = "${var.require_uppercase}"
  }

  /* only change this value if in a development environment */
  lifecycle {
    prevent_destroy = false
  }

  tags {
    Name        = "${var.app_name}-${var.environment}-user-pool"
    Environment = "${var.app_name}-${var.environment}"
  }
}

resource "aws_cognito_user_pool_client" "client" {
  name = "${var.app_name}-${var.environment}-user-pool-client"
  user_pool_id = "${aws_cognito_user_pool.pool.id}"
  generate_secret = false


  /* only change this value if in a development environment */
  lifecycle {
    prevent_destroy = false
  }
}

output "user_pool_arn" {
  value = "${aws_cognito_user_pool.pool.arn}"
}

output "user_pool_id" {
  value = "${aws_cognito_user_pool.pool.id}"
}

output "user_pool_client_id" {
  value = "${aws_cognito_user_pool_client.client.id}"
}
