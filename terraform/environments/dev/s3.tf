resource "aws_s3_bucket" "cloudsave_s3" {
    bucket = cloudsave-s3
    bucket_namespace = "account-regional"
}