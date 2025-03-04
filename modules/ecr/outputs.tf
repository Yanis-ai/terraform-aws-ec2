# ECRリポジトリのURLを出力する
output "repository_url" {
  description = "作成されたECRリポジトリのURL"
  value       = aws_ecr_repository.my_ecr_repo.repository_url
}