/*resource "aws_iam_user" "jeff" {
    name = "jeff"
}

resource "aws_iam_access_key" "jeff-access-key" {
    user = aws_iam_user.jeff
}

data "aws_iam_policy_document" "jeff-policy-doc" {
    statement {
        effect = "Allow"
        actions = [
            "s3:"
        ]
    }
} */