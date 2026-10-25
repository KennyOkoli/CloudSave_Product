output "vpc-id" {
    value = aws_vpc.CloudSave.id
}

output "private-subnets" {
    value = aws_subnet.CS_private_subnet[*].id
}

output "azones" {
    value = data.aws_availability_zones.africa_az.names
}