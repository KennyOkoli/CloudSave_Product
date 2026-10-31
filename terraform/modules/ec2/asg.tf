variable "vpc-prv-subnets" {}
variable "nacl" {}
variable "public-cidr" {}
variable "vpc_id" {}


resource "aws_launch_template" "ec2-template" {
    image_id = "ami-0016bff49059ce56b"
    instance_type = "t3.small"
    vpc_security_group_ids = [aws_security_group.ec2-comp-sg.id]
    iam_instance_profile {
      arn = aws_iam_instance_profile.ec2-profile.arn 
    }
    user_data = base64encode(
      templatefile("${path.module}/user_data.sh", {environment = local.prefix} )
    )
    #user_data = filebase64("${path.module}/user_data.sh")
}

resource "aws_autoscaling_group" "ec2-autoscale" {
    name = "ec2-autoscale-${local.prefix}"
    vpc_zone_identifier = var.vpc-prv-subnets
    desired_capacity = 2
    min_size = 1
    max_size = 4
    health_check_type = "EC2"
    health_check_grace_period = 20

    launch_template {
      id = aws_launch_template.ec2-template.id
      version = aws_launch_template.ec2-template.latest_version # Read why
    }
    instance_refresh {
      strategy = "Rolling"

      preferences {
        min_healthy_percentage = 50
        instance_warmup = 300
      }

    triggers = ["launch_template"]
  }
}

resource "aws_security_group" "ec2-compute-sg" {
    name = "ec2-task-sg-${local.prefix}"
    vpc_id = var.vpc_id
}

resource "aws_security_group" "ec2-comp-sg" {
    name = "ec2-comp-sg-${local.prefix}"
    vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "ec2-rule-1" {
    type = "ingress"
    security_group_id = aws_security_group.ec2-comp-sg.id
    cidr_blocks = [var.public-cidr]
    protocol = "tcp"
    from_port = 0
    to_port = 65535
}

resource "aws_security_group_rule" "ec2-rule-2" {
    type = "egress"
    security_group_id = aws_security_group.ec2-comp-sg.id
    cidr_blocks = [var.public-cidr]
    protocol = "tcp"
    from_port = 0
    to_port = 65535
}

resource "aws_network_acl_association" "task-subnet-nacl" {
    count = 2
    network_acl_id = var.nacl
    subnet_id = var.vpc-prv-subnets[count.index]
}
