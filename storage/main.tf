resource "aws_s3_bucket" "service_bucket" {
  bucket = "${var.service_bucket_name}"
  acl    = "private"

  tags {
    Name = "${var.app_name}-${var.environment}-tasks"
    Environment = "${var.app_name}-${var.environment}"
  }
}
