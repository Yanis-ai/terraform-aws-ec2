# VPC��ID���o�͂���
output "vpc_id" {
  description = "�쐬���ꂽVPC��ID"
  value       = aws_vpc.main.id
}

# �T�u�l�b�g��ID���o�͂���
output "subnet_ids" {
  description = "�쐬���ꂽ�T�u�l�b�g��ID���X�g"
  value       = [for subnet in aws_subnet.subnet : subnet.id]
}

# SSH�A�N�Z�X�p�Z�L�����e�B�O���[�v��ID���o�͂���
output "security_group_id" {
  description = "SSH�A�N�Z�X�p�Z�L�����e�B�O���[�v��ID"
  value       = aws_security_group.ssh_access.id
}