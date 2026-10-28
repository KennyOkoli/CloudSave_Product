data "aws_iam_openid_connect_provider" "github-id" {
    arn = "arn:aws:iam::871145212791:oidc-provider/token.actions.githubusercontent.com"
}

locals {
  oidc_arn = data.aws_iam_openid_connect_provider.github-id.arn
}

data "aws_iam_policy_document" "oidc_policy_doc" {
    statement {
        effect = "Allow"
        principals {
            type = "Federated"
            identifiers = [local.oidc_arn]
        }
        actions = ["sts:AssumeRoleWithWebIdentity"]
        condition {
            test = "StringEquals"
            variable = "token.actions.githubusercontent.com:aud"
            values = ["sts.amazonaws.com"]
        }
        condition {
            test = "StringLike"
            variable = "token.actions.githubusercontent.com:sub"
            values = ["repo:KennyOkoli@334668853/CloudSave@1426990249:*"] # In future projects find out how to streamline this permission
        }       
    }
}

resource "aws_iam_role" "github-role" {
    name = "github-role"
    assume_role_policy = data.aws_iam_policy_document.oidc_policy_doc.json
}

data "aws_iam_policy_document" "github-policy-doc" {
    statement {
      effect = "Allow"
      actions = [
        "ecr:GetAuthorisationToken"
      ]
      resources = ["*"] # Similar to ecr login
    }
    statement {
      effect = "Allow"
      actions = [
        "ecr:BatchCheckLayerAvailability",
        "ecr:CompleteLayerUpload",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart"
      ]
      resources = ["*"]
    }
    statement {
      effect = "Allow"
      actions = [
        "ecs:RegisterTaskDefinition",
        "ecs:DescribeTaskDefinition",
        "ecs:UpdateService",
        "ecs:DescribeServices"     
      ]
      resources = ["*"] # One arn for ecs while the other for ecs task def
    }
    statement {
      effect = "Allow"
      actions = ["iam:PassRole"]
      resources = ["*"] # Specify what role to pass
    }
}