output "db_sg"{
    value = aws_security_group.mysql_db_sg.id
}

output "ec2_arn" {
    value = aws_instance.db_ec2_jumphost.arn
}