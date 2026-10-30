data "aws_iam_policy_document" "ec2-trust" {
    statement {
        effect = "Allow"
        principals {
            type = "Service"
            identifiers = ["ec2.amazonaws.com"]
        }
        actions = ["sts:AssumeRole"]
    }
}

resource "aws_iam_role" "ec2-role" {
    name = "ec2-role-${local.prefix}"
    assume_role_policy = data.aws_iam_policy_document.ec2-trust.json
}

resource "aws_iam_role_policy_attachment" "ec2-role-policy-ecs" {
    role = aws_iam_role.ec2-role.id
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ec2-role-policy-ssm" {
    role = aws_iam_role.ec2-role.id
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2-profile" {
    name = "ec2-profile"
    role = aws_iam_role.ec2-role.name
}