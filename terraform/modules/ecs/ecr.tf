resource "aws_ecr_repository" "cloudsave-repo" {
    name = "cloudsave-repo-${local.prefix}"
    image_tag_mutability = "IMMUTABLE"
}