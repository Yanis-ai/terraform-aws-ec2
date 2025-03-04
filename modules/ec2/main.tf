# �V����SSH�L�[�y�A�𐶐�����
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# ���[�J���Ƀv���C�x�[�g�L�[��ۑ�����
resource "local_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/private_key.pem"
  file_permission = "0600"
}

# AWS���SSH�L�[�y�A���쐬����
resource "aws_key_pair" "ssh_key_pair" {
  key_name   = var.key_pair_name
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# EC2�C���X�^���X���쐬����
resource "aws_instance" "ec2_instance" {
  ami                    = var.ami_id            # ���ۂ�AMI ID�ɒu�������Ă�������
  instance_type          = var.instance_type     # �K�v��EC2�C���X�^���X�^�C�v��I�����Ă�������
  subnet_id              = var.subnet_id         # �C���X�^���X��z�u����T�u�l�b�g
  key_name               = aws_key_pair.ssh_key_pair.key_name

  associate_public_ip_address = true
  security_groups             = [var.security_group]  # �Z�L�����e�B�O���[�v

  tags = {
    Name = "${var.test_prefix}-ec2-instance"
  }
}

# Docker���C���X�g�[�����A�C���[�W���v������X�N���v�g
locals {
  install_docker_pull_image_script = <<EOT
#!/bin/bash
# �V�X�e�����X�V
sudo apt-get update -y
# �K�v�Ȉˑ��֌W���C���X�g�[��
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
# Docker�̌���GPG����ǉ�
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
# Docker�̃��|�W�g����ǉ�
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
# �p�b�P�[�W���X�g���X�V
sudo apt-get update -y
# Docker���C���X�g�[��
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# AWS ECR�Ƀ��O�C��
account_id=$(aws sts get-caller-identity --query Account --output text)
aws ecr get-login-password --region "ap-northeast-1" | sudo docker login --username AWS --password-stdin $account_id.dkr.ecr.ap-northeast-1.amazonaws.com

# Docker�C���[�W���v��
sudo docker pull $account_id.dkr.ecr.ap-northeast-1.amazonaws.com/batch-test-repo:latest
EOT
}

# null_resource ���g�p����Docker�C���X�g�[���X�N���v�g�����s
resource "null_resource" "install_docker" {
  provisioner "local-exec" {
    command = <<EOT
      sleep 90
ssh -o StrictHostKeyChecking=no -i ${path.module}/private_key.pem ubuntu@${aws_instance.ec2_instance.public_ip} << EOF
${local.install_docker_pull_image_script}
EOF
EOT
}

  depends_on = [aws_instance.ec2_instance]
}