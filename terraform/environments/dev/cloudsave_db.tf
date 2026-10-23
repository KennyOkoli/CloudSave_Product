data "aws_secretsmanager_secret_version" "db-secrets" {
    secret_id = aws_secretsmanager_secret.cloudsave-db-secrets.id
}
 locals{
    db_credentials = jsondecode(data.aws_secretsmanager_secret_version.db-secrets.secret_string)
 }

resource "aws_db_instance" "CloudSave_db"{
    db_name = "CloudSave_db"
    identifier = "cloudsave"
    engine = "mysql"
    engine_version = "8.4.11"
    instance_class = "db.t3.micro"
    storage_type = "gp3"
    allocated_storage = 20
    username = local.db_credentials.username
    password = local.db_credentials.password
    multi_az = false
    skip_final_snapshot = true
    db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
    vpc_security_group_ids = [aws_security_group.mysql_db_sg.id]
    parameter_group_name = aws_db_parameter_group.db_parameter.name
}

resource "aws_db_parameter_group" "db_parameter" {
    name_prefix = "mysql84-parameter"
    family = "mysql8.4"

    parameter {
      name = "max_connections"
      value = 500
    }
}

resource "aws_db_subnet_group" "db_subnet_group" {
    name = "db_subnet_group"
    subnet_ids = aws_subnet.db_subnet[*].id
}

resource "aws_security_group" "mysql_db_sg" {
    name = "postgres_db_sg"
    vpc_id = aws_vpc.CloudSave.id
}

resource "aws_security_group_rule" "mysql_db_sg_rule"{
    security_group_id = aws_security_group.mysql_db_sg.id
    cidr_blocks = [var.public_ip]
    type = "ingress"
    protocol = "tcp"
    from_port = 3306
    to_port = 3306
}

resource "aws_security_group_rule" "mysql_db_sg_rule_eg"{
    security_group_id = aws_security_group.mysql_db_sg.id
    cidr_blocks = [var.public_ip]
    type = "egress"
    protocol = "tcp"
    from_port = 1024
    to_port = 65535
}

resource "aws_subnet" "db_subnet" {
    count = 2
    vpc_id = aws_vpc.CloudSave.id
    cidr_block = "172.0.${count.index + 200}.0/24"
    availability_zone = data.aws_availability_zones.africa_az.names[count.index]
    tags={
        name = var.db_subnet_tags[count.index]
    }
}

resource "aws_network_acl" "db_nacl" {
    vpc_id = aws_vpc.CloudSave.id
    ingress{
        rule_no = 1
        protocol = "tcp"
        cidr_block = var.public_ip
        action = "allow"
        from_port = 0
        to_port = 65535
    }
     egress{
        rule_no = 1
        protocol = "tcp"
        cidr_block = var.public_ip
        action = "allow"
        from_port = 0
        to_port = 65535
    }
}

resource "aws_network_acl_association" "db_subnet_to_nacl" {
    count = 2
    subnet_id = aws_subnet.db_subnet[count.index].id
    network_acl_id = aws_network_acl.db_nacl.id
}

resource "aws_route_table" "db_prv_route" {
    vpc_id = aws_vpc.CloudSave.id
}

resource "aws_route_table_association" "db_subnet_to_route" {
    count = 2
    route_table_id = aws_route_table.db_prv_route.id
    subnet_id = aws_subnet.db_subnet[count.index].id
}

resource "aws_instance" "db_ec2_jumphost" {
    ami = "ami-0527144c5a042f57d"
    instance_type = "t3.micro"
    subnet_id = aws_subnet.CS_private_subnet[0].id
    vpc_security_group_ids = [aws_security_group.ec2_sg.id]
    iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

    user_data = <<EOF
    #!/bin/bash

    exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
    dnf update -y
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
    
    EOF
}
resource "aws_security_group" "ec2_sg" {
    name = "ec2-db-sg"
    vpc_id = aws_vpc.CloudSave.id
}

resource "aws_security_group_rule" "ec2_sg_rule"{
    security_group_id = aws_security_group.ec2_sg.id
    cidr_blocks = [var.public_ip]
    type = "ingress"
    protocol = "tcp"
    from_port = 0
    to_port = 65535
}

resource "aws_security_group_rule" "ec2_sg_rule_eg"{
    security_group_id = aws_security_group.ec2_sg.id
    cidr_blocks = [var.public_ip]
    type = "egress"
    protocol = "tcp"
    from_port = 0
    to_port = 65535
}

resource "aws_iam_role" "ec2_role" {
   name = "ec2_role"
   assume_role_policy = jsonencode(
     {
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Principal = {"Service" = "ec2.amazonaws.com"}
            Action = ["sts:AssumeRole"]
          }
        ]
     }
   )
}

resource "aws_iam_role_policy_attachment" "ec2_role_policy" {
    role = aws_iam_role.ec2_role.id
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
    name = "ec2_instance_profile"
    role = aws_iam_role.ec2_role.name   
}