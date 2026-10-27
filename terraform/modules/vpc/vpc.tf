terraform {
  required_providers {
     aws = {
        source = "hashicorp/aws"
        version = "~>6.0"
    }
  }
}

variable "account"{
    type = string
    default = "871145212791"
}

variable "aws_region"{
    type = string
    default = "af-south-1"
}

variable "public_ip"{
    type = string
    default = "0.0.0.0/0"
}

variable "CS_cidr_block"{
    type = string
    default = "172.0.0.0/16"
}

variable "nat_tags" {
    default = ["nat-af-1a", "nat-af-1b"]
}

variable "private_subnets_tags"{
    default = ["prv-af-1a", "prv-af-1b"]
}

variable "public_subnet_tags"{
    default = ["pub-af-1a", "pub-af-1b"]
}

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

# ---------------------------- Private Resources ---------------------------
resource "aws_subnet" "CS_private_subnet"{
    count = 2
    vpc_id = aws_vpc.CloudSave.id
    cidr_block = "172.0.${count.index + 100}.0/24"
    availability_zone = data.aws_availability_zones.africa_az.names[count.index]

    tags ={
        name = var.private_subnets_tags[count.index]
    }
}
/*
resource "aws_eip" "cs_eip" {
    count = 2
}

resource "aws_nat_gateway" "cs_nat_gateway" {
    count = 2
    allocation_id = aws_eip.cs_eip[count.index].id
    subnet_id = aws_subnet.CS_public_subnet[count.index].id

    tags ={
        name = var.nat_tags[count.index]
    }
}

resource "aws_route_table" "CS_private-route"{
    count = 2
    vpc_id = aws_vpc.CloudSave.id
    route{
        cidr_block = var.public_ip
        nat_gateway_id = aws_nat_gateway.cs_nat_gateway[count.index].id
    }
}*/

resource "aws_network_acl" "CS_acl_private" {
    vpc_id = aws_vpc.CloudSave.id
    subnet_ids = aws_subnet.CS_private_subnet[*].id
    ingress {
        rule_no = 1
        cidr_block = var.public_ip
        action = "allow"
        protocol = "tcp"
        from_port = 0
        to_port = 65535
    }
    egress {
        rule_no = 1
        cidr_block = var.public_ip
        action = "allow"
        protocol = "tcp"
        from_port = 0
        to_port = 65535
    }
}
/*
resource "aws_route_table_association" "route_private_subnet" {
    count = 2
    route_table_id = aws_route_table.CS_private-route[count.index].id
    subnet_id = aws_subnet.CS_private_subnet[count.index].id
}

resource "aws_network_acl_association" "nacls_private"{
    count = 2
    network_acl_id = aws_network_acl.CS_acl_private.id
    subnet_id = aws_subnet.CS_private_subnet[count.index].id
}*/
