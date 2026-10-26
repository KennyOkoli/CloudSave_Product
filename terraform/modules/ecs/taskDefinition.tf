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
        cpu = 525
        memory = 1024
        portMappings = [{
            containerPort = 4000
        }]
        }
    ])
}
