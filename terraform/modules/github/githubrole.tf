resource "aws_iam_openid_connect_provider" "github-id" {
    url = "https://token.actions.githubusercontent.com"
    client_id_list = ["sts.amazonaws.com"]
}

data "aws_iam_policy_document" "oidc_policy_doc" {
    statement {
        effect = "Allow"
        principals {
            type = "Federated"
            identifiers = [aws_iam_openid_connect_provider.github-id.arn]
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
            values = ["repo:KennyOkoli@334668853/CloudSave@1426990249:*"]
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
      resources = ["*"]
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
      resources = ["*"]
    }
    # Github needs permissions to pull from ecr
    # Upload image into ecr
    # Update ecs
    # update task def
}