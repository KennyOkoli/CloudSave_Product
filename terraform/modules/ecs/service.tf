#resource "aws_ecs_service" "cloudsave-service" {}




variable "vpc" {}

resource "aws_security_group" "task-sg" {
    name = "task-sg"
    vpc_id = var.vpc
}

/*
resource "aws_security_group_rule" "task-rule-1" {
    type = "ingress"

}*/



resource "aws_iam_role" "task-role" {
    name = "task-role"
    assume_role_policy = data.aws_iam_policy_document.task-def_trust.json
}

resource "aws_iam_role_policy" "task-role-policy" {
    name = "task-role-policy"
    role = aws_iam_role.task-role.id
    policy = data.aws_iam_policy_document.task-actions.json
}

data "aws_iam_policy_document" "task-actions" {
    statement {
       effect = "Allow"
       actions = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject",
          "secretsmanager:GetSecretValue"
       ]
       resources = [
          var.s3,
          var.secrets
       ]
    }
}

variable "s3" {}
variable "secrets" {}