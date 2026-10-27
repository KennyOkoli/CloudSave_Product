variable "public-subnet" {}
variable "ecs-sg-var" {}


resource "aws_alb_target_group" "cloudsave-target-group" {
    vpc_id = var.vpc_id
    target_type = "ip"
    protocol = "HTTP"
    port = 4000
    
    health_check {
    protocol = "HTTP"
    port = 4000
    path = "/" # look up on this
    interval = 10
    timeout = 5
    healthy_threshold = 3
    unhealthy_threshold = 2
    }
}

/*resource "aws_alb" "cloudsave-alb" {
    name = "cloudsave-alb"
    security_groups = [aws_security_group.alb-sg.id]
    subnets = var.public-subnet
    internal = false
    load_balancer_type = "application"
}

resource "aws_alb_listener" "cloudsave-alb-listener" {
    load_balancer_arn = aws_alb.cloudsave-alb.id
    protocol = "HTTP"
    port = 80
    default_action {
      type = "forward"
      forward {
        target_group {
          arn = aws_alb_target_group.cloudsave-target-group.arn
        }
      }
    }
}*/

resource "aws_security_group" "alb-sg" {
    name = "alb-sg"
    vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "alb-rule-1" {
    type = "ingress"
    security_group_id = aws_security_group.alb-sg.id
    cidr_blocks = [var.public-cidr]
    protocol = "tcp"
    from_port = 80
    to_port = 80
}

resource "aws_security_group_rule" "alb-rule-4" {
    type = "egress"
    security_group_id = aws_security_group.alb-sg.id
    source_security_group_id = var.ecs-sg-var
    protocol = "tcp"
    from_port = 4000
    to_port = 4000
}
