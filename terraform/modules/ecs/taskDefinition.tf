variable "db_port" {
    default = "3306"
}
variable "db_host" {
    default = "cloudsave.czqsco2eaxj9.af-south-1.rds.amazonaws.com"
}/*
variable "db_name" {}
variable "db_username" {}
variable "db_password" {}*/
variable "s3_bucket" {}
/*
resource "aws_ecs_task_definition" "cloudsave-task-def" {
    network_mode = "awsvpc"
    requires_compatibilities = ["EC2"]
    family = "web-app"
    execution_role_arn = aws_iam_role.task-def-role.arn
    task_role_arn = aws_iam_role.task-role.arn

    container_definitions = jsonencode([
        {
        name = "cloudsave-app"
        image = "nginx:latest"
        cpu = 256
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
            }
            ]
        }
    ])
}
*/
