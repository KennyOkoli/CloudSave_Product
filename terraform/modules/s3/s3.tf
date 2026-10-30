terraform {
  required_providers {
     aws = {
        source = "hashicorp/aws"
        version = "~>6.0"
    }
  }
}
variable "environment" {}

locals {
    prefix = var.environment
}

variable "bucket_name" {}

resource "aws_s3_bucket" "cloudsave_s3" {
    bucket = var.bucket_name
}

resource "aws_s3_bucket_cors_configuration" "cloudsave_s3_cors" {
    bucket = aws_s3_bucket.cloudsave_s3.id

    cors_rule {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "PUT", "POST"]
      allowed_origins = ["*"]
      expose_headers = ["ETag"]
      max_age_seconds = 3000
    }
}