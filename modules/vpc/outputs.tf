# VPCのIDを出力する
output "vpc_id" {
  description = "作成されたVPCのID"
  value       = aws_vpc.main.id
}

# サブネットのIDを出力する
output "subnet_ids" {
  description = "作成されたサブネットのIDリスト"
  value       = [for subnet in aws_subnet.subnet : subnet.id]
}

# SSHアクセス用セキュリティグループのIDを出力する
output "security_group_id" {
  description = "SSHアクセス用セキュリティグループのID"
  value       = aws_security_group.ssh_access.id
}