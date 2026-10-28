# terraform {
#   required_providers {
#      aws = {
#         source = "hashicorp/aws"
#         version = "~>6.0"
#     }
#   }
# }



# resource "aws_secretsmanager_secret" "cloudsave-db-secrets" {
#     name = "cloudsave-db-secrets"
# }

# resource "aws_secretsmanager_secret_version" "db-secrets" {
#     secret_id = aws_secretsmanager_secret.cloudsave-db-secrets.id
#     secret_string = jsonencode(var.db-credentials)
# }

# variable "db-credentials" {
#   default = {
#     username = "Kenny"
#     password = "kenny2007"
#   }
#   sensitive = true
# } 