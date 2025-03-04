# 新しいSSHキーペアを生成する
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# ローカルにプライベートキーを保存する
resource "local_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/private_key.pem"
  file_permission = "0600"
}

# AWS上でSSHキーペアを作成する
resource "aws_key_pair" "ssh_key_pair" {
  key_name   = var.key_pair_name
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# EC2インスタンスを作成する
resource "aws_instance" "ec2_instance" {
  ami                    = var.ami_id            # 実際のAMI IDに置き換えてください
  instance_type          = var.instance_type     # 必要なEC2インスタンスタイプを選択してください
  subnet_id              = var.subnet_id         # インスタンスを配置するサブネット
  key_name               = aws_key_pair.ssh_key_pair.key_name

  associate_public_ip_address = true
  security_groups             = [var.security_group]  # セキュリティグループ

  tags = {
    Name = "${var.test_prefix}-ec2-instance"
  }
}

# Dockerをインストールし、イメージをプルするスクリプト
locals {
  install_docker_pull_image_script = <<EOT
#!/bin/bash
# システムを更新
sudo apt-get update -y
# 必要な依存関係をインストール
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
# Dockerの公式GPG鍵を追加
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
# Dockerのリポジトリを追加
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
# パッケージリストを更新
sudo apt-get update -y
# Dockerをインストール
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# AWS ECRにログイン
account_id=$(aws sts get-caller-identity --query Account --output text)
aws ecr get-login-password --region "ap-northeast-1" | sudo docker login --username AWS --password-stdin $account_id.dkr.ecr.ap-northeast-1.amazonaws.com

# Dockerイメージをプル
sudo docker pull $account_id.dkr.ecr.ap-northeast-1.amazonaws.com/batch-test-repo:latest
EOT
}

# null_resource を使用してDockerインストールスクリプトを実行
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