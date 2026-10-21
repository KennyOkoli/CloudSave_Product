data "aws_availability_zones" "africa_az"{
    state = "available"
}

resource "aws_vpc" "CloudSave" {
    cidr_block = var.CS_cidr_block
    enable_dns_hostnames = true
    enable_dns_support = true
}

resource "aws_subnet" "CS_public_subnet"{
    count = 2
    vpc_id = aws_vpc.CloudSave.id
    cidr_block = "172.0.${count.index}.0/24"
    availability_zone = data.aws_availability_zones.africa_az.names[count.index]
    map_public_ip_on_launch = true

    tags ={
        name = var.public_subnet_tags[count.index]
    }
}

resource "aws_internet_gateway" "CS_gateway"{
    vpc_id = aws_vpc.CloudSave.id
}

resource "aws_route_table" "CS_public_route"{
    vpc_id = aws_vpc.CloudSave.id
    route {
        cidr_block = var.public_ip
        gateway_id = aws_internet_gateway.CS_gateway.id
    }
}

resource "aws_network_acl" "CS_public_acl"{
    vpc_id = aws_vpc.CloudSave.id
    subnet_ids = aws_subnet.CS_public_subnet[*].id
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

resource "aws_route_table_association" "CS_route_public_subnet" {
    count = 2
    route_table_id = aws_route_table.CS_public_route.id
    subnet_id = aws_subnet.CS_public_subnet[count.index].id
}

resource "aws_network_acl_association" "CS_nacl_association" {
    count = 2
    network_acl_id = aws_network_acl.CS_public_acl.id
    subnet_id = aws_subnet.CS_public_subnet[count.index].id
}
