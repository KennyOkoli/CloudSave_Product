resource "aws_ecr_repository" "cloudsave-repo" {
    name = "cloudsave-repo"
    image_tag_mutability = "IMMUTABLE"
}