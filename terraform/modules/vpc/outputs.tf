output "vpc-id" {
    value = aws_vpc.CloudSave.id
}

output "private-subnets" {
    value = aws_subnet.CS_private_subnet[*].id
}

output "azones" {
    value = data.aws_availability_zones.africa_az.names
}

output "public-cidr" {
    value = var.public_ip
}

output "vpc-nacls" {
    value = aws_network_acl.CS_acl_private.id
}

output "vpc-public-subnet" {
    value = aws_subnet.CS_public_subnet[*].id
}

# For a commit