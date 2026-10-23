resource "aws_s3_bucket" "cloudsave_s3" {
    bucket = "cloudsave/bucket"
    bucket_namespace = "account-regional"
}