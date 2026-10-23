resource "aws_secretsmanager_secret" "cloudsave_secrets" {
    name = "cloudsave-secrets"
}
/*
resource "aws_secretsmanager_secret_version" "db-secrets" {
    secret_id = aws_secretsmanager_secret.cloudsave_secrets.id
    secret_string = 
}

variable "db-credentials" {
  default = {
    username = "Kenny"
    password = "kenny2007"
  }
} */