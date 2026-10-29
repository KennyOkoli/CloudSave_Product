output "secret-manager-arn" {
    value = aws_secretsmanager_secret.cloudsave-db-secrets.arn
}

output "secret-id" {
    value = aws_secretsmanager_secret.cloudsave-db-secrets.id
}