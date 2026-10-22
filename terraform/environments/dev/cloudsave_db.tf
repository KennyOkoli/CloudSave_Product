/*resource "aws_db_instance" "CloudSave_db"{
    db_name = "CloudSave_db"
    identifier = "cloudsave"
    engine = "mysql"
    engine_version = "8.4.11"
    instance_class = "db.t3.micro"
    storage_type = "gp3"
    allocated_storage = 20
    username = file("${path.module}/mysql_username.txt")
    password = file("${path.module}/mysql_password.txt")
    multi_az = false
    skip_final_snapshot = true
    db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
    vpc_security_group_ids = [aws_security_group.mysql_db_sg.id]
    parameter_group_name = aws_db_parameter_group.db_parameter.name
}

resource "aws_db_subnet_group" "db_subnet_group" {
    name = "db_subnet_group"
    subnet_ids = [aws_subnet.db_subnet.id]
}
*/
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
    vpc_id = aws_vpc.CloudSave.id
    cidr_block = "172.0.${count.index + 200}.0/24"
    availability_zone = data.aws_availability_zones.africa_az.name[0]
    map_public_ip_on_launch = true  # For now the db is in a public subnet for dev use

    tags={
        name = var.db_subnet_tags
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

resource "aws_route_table" "db_route" {
    vpc_id = aws_vpc.CloudSave
    route{
        cidr_block = var.public_ip
        gateway_id = aws_internet_gateway.CS_gateway.id
    }
}

resource "aws_route_table_association" "db_subnet_to_route" {
    count = 2
    route_table_id = aws_route_table.db_route.id
    subnet_id = aws_subnet.db_subnet[count.index].id
}
