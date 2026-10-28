output "ecs-sg" {
    value = aws_security_group.task-sg.id
}

output "ecr-arn" {
    value = aws_ecr_repository.cloudsave-repo.arn
}