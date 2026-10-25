resource "aws_ecs_task_definition" "cloudsave-task-def" {
    network_mode = "awsvpc"
    requires_compatibilities = "EC2"
    family = "web-app"
    execution_role_arn = aws_iam_role.task-def-role.arn

    container_definitions = jsonencode([
        {
        name = "cloudsave-app"
        image = "nginx:latest"
        cpu = 525
        memory = 1024
        portMappings = [{
            containerPort = 4000
        }]
        }
    ])
}

data "aws_iam_policy_document" "task-def_trust" {
    statement {
      effect = "Allow"
      principals {
        type = "Service"
        identifiers = ["ecs-task.amazonaws.com", "ecs.amazonaws.com"]
      }
      actions = ["sts:AssumeRole"]
    }
}

resource "aws_iam_role" "task-def-role" {
    name = "task-def-role"
    assume_role_policy = data.aws_iam_policy_document.task-def_trust.json
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