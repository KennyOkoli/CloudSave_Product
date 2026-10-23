data "aws_ssoadmin_instances" "center" {
    provider = aws.identity_center
}

locals {
    idStore_id = tolist(data.aws_ssoadmin_instances.center.identity_store_ids)[0]
    Account_arn = tolist(data.aws_ssoadmin_instances.center.arns)[0]
}

/*
resource "aws_identitystore_user" "jeff" {
    provider = aws.identity_center
    identity_store_id = local.idStore_id
    user_name = "Jeff"
    display_name = "Jeff"
    name {
        given_name = "Jeff"
        family_name = "Okoli"
    }
    emails{
        value = var.jeff_email
    }
}*/

resource "aws_ssoadmin_permission_set" "use_s3" {
    name = "use-s3"
    provider = aws.identity_center
    instance_arn = local.Account_arn
}

data "aws_iam_policy_document" "use_s3_policy" {
    statement {
        effect = "Allow"
        actions = [
            "s3:ListBucket",
            "s3:GetObject",
            "s3:PutObject",
            "s3:DeleteObject"
        ]
        resources = [
            aws_s3_bucket.cloudsave_s3.arn,
            "${aws_s3_bucket.cloudsave_s3.arn}/*"]
    }
}

resource "aws_ssoadmin_permission_set_inline_policy" "use_s3_attachcment" {
    provider = aws.identity_center
    permission_set_arn = aws_ssoadmin_permission_set.use_s3.arn
    inline_policy = data.aws_iam_policy_document.use_s3_policy.json
    instance_arn = local.Account_arn
}

# Checkout region for ssoadmin, does the ssoadmin_region work in a similar way to provider:aws:region:
# Reserch more on identity_store