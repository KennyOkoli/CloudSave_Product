resource "aws_cloudwatch_log_group" "cloudsave_logs" {
    name = "/cloudsave/logs/${local.prefix}"
    tags ={
        name = "task-log"
    }
}