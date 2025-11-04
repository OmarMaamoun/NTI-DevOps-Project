resource "aws_ecr_repository" "api_app" {
  name = "${var.environment}-api"
  image_tag_mutability = var.image_tag_mutable
}

resource "aws_ecr_repository" "web_app" {
  name = "${var.environment}-web"
  image_tag_mutability = var.image_tag_mutable
}