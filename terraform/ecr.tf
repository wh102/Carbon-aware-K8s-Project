resource "aws_ecr_repository" "flask_app" {
  name         = var.project_name
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }
}
