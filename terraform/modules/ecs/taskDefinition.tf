variable "db_port" {
    default = "3306"
}
variable "db_host" {
    default = "cloudsave-dev.czqsco2eaxj9.af-south-1.rds.amazonaws.com"
}
variable "db_name" {}
variable "db_username" {}
variable "db_password" {}
variable "s3_bucket" {}

variable "task-def" {}

resource "aws_ecs_task_definition" "cloudsave-task-def" {
    network_mode = "awsvpc"
    requires_compatibilities = ["EC2"]
    family = var.task-def
    execution_role_arn = aws_iam_role.task-def-role.arn
    task_role_arn = aws_iam_role.task-role.arn

    container_definitions = jsonencode([
        {
        name = "cloudsave-app"
        image = "nginx:latest"
        cpu = 256 # Lookup
        memory = 512
        portMappings = [{
            containerPort = 4000
        }]
        environment = [
            {   
                name = "DB_NAME"
                value = var.db_name
            },
            {
                name = "DB_USERNAME"
                value = var.db_username
            },
            {
                name = "DB_PASSWORD"
                value = var.db_password
            },
            {
                name = "DB_PORT"
                value = var.db_port
            },
            {
                name = "DB_HOST"
                value = var.db_host
            },
            {   name = "S3_BUCKET"
                value = var.s3_bucket
            },
            {
                name = "JWT_SECRET"
                value = "abcdefghijklmnopqrstuvwxyhiyvjgyukvfgyjm"
            },
            {
                name = "ENABLE_BACKGROUND_JOBS"
                value = "true"
            },
            {
                name = "SKIP_DB_CHECK"
                value = "false"
            },
            {
                name = "SKIP_S3_CHECK"
                value = "false"
            },
            {
                name = "AWS_REGION"
                value = "af-south-1"
            },
            {
                name = "APP_ORIGIN"
                value = "http://localhost:4000"
            }
        ]
            logConfiguration = {
            logDriver = "awslogs"
            options = {
                awslogs-group = aws_cloudwatch_log_group.cloudsave_logs.name
                awslogs-region = var.region
                awslogs-stream-prefix = "ecs"
            }
        }
        }
    ])
}
variable "region" {}
