variable "vpc-prv-subnets" {}
variable "nacl" {}
variable "public-cidr" {}
variable "vpc_id" {}


resource "aws_launch_template" "ec2-template" {
    image_id = "ami-0016bff49059ce56b"
    instance_type = "t3.micro"
    vpc_security_group_ids = [aws_security_group.ec2-compute-sg.id]
    iam_instance_profile {
      name = "ec2-instance-profile"
      arn = aws_iam_instance_profile.ec2-profile.arn 
    }
    user_data = <<EOF
    #!/bin/bash
    exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

    dnf update -y
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent

    echo "ECS_CLUSTER=cs_container_cluster" > /etc/ecs/ecs.config
    systemctl restart ecs

    EOF
}

resource "aws_autoscaling_group" "ec2-autoscale" {
    name = "ec2-autoscale"
    vpc_zone_identifier = var.vpc-prv-subnets
    desired_capacity = 2
    min_size = 2
    max_size = 3
    health_check_type = "EC2"
    health_check_grace_period = 5

    launch_template {
      name = "asg-launch"
      id = aws_launch_template.ec2-template.id
      version = "$Latest"
    }
}

resource "aws_security_group" "ec2-compute-sg" {
    name = "task-sg"
    vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "ec2-rule-1" {
    type = "ingress"
    security_group_id = aws_security_group.ec2-compute-sg.id
    cidr_blocks = [var.public-cidr]
    protocol = "tcp"
    from_port = 0
    to_port = 65535
}

resource "aws_security_group_rule" "ec2-rule-2" {
    type = "egress"
    security_group_id = aws_security_group.ec2-compute-sg.id
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
