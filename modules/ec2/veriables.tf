variable "test_prefix" {
  description = "�o�b�`�e�X�g���̃v���t�B�b�N�X"
  type        = string
}

variable "key_pair_name" {
  description = "SSH�L�[�y�A�̖��O"
  type        = string
}

variable "ami_id" {
  description = "EC2�C���X�^���X��AMI ID"
  type        = string
}

variable "instance_type" {
  description = "EC2�C���X�^���X�̃^�C�v"
  type        = string
  default     = "t2.micro"
}

variable "subnet_id" {
  description = "EC2�C���X�^���X���N������T�u�l�b�gID"
  type        = string
}

variable "security_group" {
  description = "EC2�C���X�^���X�Ɋ��蓖�Ă�Z�L�����e�B�O���[�v"
  type        = string
}