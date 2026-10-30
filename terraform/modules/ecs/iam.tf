resource "aws_iam_role" "task-role" {
    name = "task-role"
    assume_role_policy = data.aws_iam_policy_document.task_def_trust.json
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
          "secretsmanager:GetSecretValue",
          "logs:CreateLogStream",
          "logs:PullLogEvents"
       ]
       resources = [
          var.s3,
          "${var.s3}/*",
          var.secrets,
          aws_cloudwatch_log_group.cloudsave_logs.arn
       ]
    }
}


data "aws_iam_policy_document" "task_def_trust" {
    statement {
      effect = "Allow"
      principals {
        type = "Service"
        identifiers = ["ecs-tasks.amazonaws.com", "ecs.amazonaws.com"]
      }
      actions = ["sts:AssumeRole"]
    }
}

resource "aws_iam_role" "task-def-role" {
    name = "task-def-role-${local.prefix}"
    assume_role_policy = data.aws_iam_policy_document.task_def_trust.json
}

resource "aws_iam_role_policy" "task-def-policy" {
    name = "task-def-policy"
    role = aws_iam_role.task-def-role.id
    policy = data.aws_iam_policy_document.role-policy.json
}

data "aws_iam_policy_document" "role-policy" {
    statement {
        effect = "Allow"
        actions = [
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchCheckLayerAvailability",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
        ]
        resources = [aws_ecr_repository.cloudsave-repo.arn]
    }
    statement {
        effect = "Allow"
        actions = ["ecr:GetAuthorizationToken"]
        resources = ["*"]
    }
    #
}