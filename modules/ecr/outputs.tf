# ECR���|�W�g����URL���o�͂���
output "repository_url" {
  description = "�쐬���ꂽECR���|�W�g����URL"
  value       = aws_ecr_repository.my_ecr_repo.repository_url
}