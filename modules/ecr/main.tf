resource "aws_ecr_repository" "my_ecr_repo" {
  name = var.repository_name
  force_delete = true
}