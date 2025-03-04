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
# locals {
#   install_docker_pull_image_script = <<EOT
# #!/bin/bash
# # システムを更新
# sudo apt-get update -y
# # 必要な依存関係をインストール
# sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
# # Dockerの公式GPG鍵を追加
# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
# # Dockerのリポジトリを追加
# sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
# # パッケージリストを更新
# sudo apt-get update -y
# # Dockerをインストール
# sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# # AWS ECRにログイン
# account_id=$(aws sts get-caller-identity --query Account --output text)
# aws ecr get-login-password --region "ap-northeast-1" | sudo docker login --username AWS --password-stdin $account_id.dkr.ecr.ap-northeast-1.amazonaws.com

# # Dockerイメージをプル
# sudo docker pull $account_id.dkr.ecr.ap-northeast-1.amazonaws.com/batch-test-repo:latest
# EOT
# }
locals {
  install_docker_pull_image_script = <<EOT
#!/bin/bash
set -e

# 定??量
S3_BUCKET_NAME="${module.s3_bucket.bucket_name}"
S3_INPUT_PATH="s3://$S3_BUCKET_NAME/input/"
S3_OUTPUT_PATH="s3://$S3_BUCKET_NAME/output/"
LOCAL_INPUT_DIR="/data/input"
LOCAL_OUTPUT_DIR="/data/output"
OUTPUT_CSV="$LOCAL_OUTPUT_DIR/output.csv"

# 1. 更新系?并安装必要工具
sudo apt-get update -y
sudo apt-get install -y awscli tar jq

# 2. ?建本地目?
mkdir -p $LOCAL_INPUT_DIR $LOCAL_OUTPUT_DIR

# 3. 下? S3 上的所有 .tar.gz 文件
aws s3 cp $S3_INPUT_PATH $LOCAL_INPUT_DIR --recursive --exclude "*" --include "*.tar.gz"

# 4. 安装 Docker
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# 5. 登? AWS ECR 并拉取 Docker ?像
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="ap-northeast-1"
ECR_URL="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/batch-test-repo"

aws ecr get-login-password --region "$REGION" | sudo docker login --username AWS --password-stdin "$ECR_URL"
sudo docker pull "$ECR_URL:latest"

# 6. ?行 Docker 容器?行解?，并????
echo "filename,extract_time(s)" > $OUTPUT_CSV

for file in $LOCAL_INPUT_DIR/*.tar.gz; do
    [[ -f "$file" ]] || continue

    filename=$(basename "$file")
    start_time=$(date +%s)

    sudo docker run --rm -v "$LOCAL_INPUT_DIR":/input -v "$LOCAL_OUTPUT_DIR":/output "$ECR_URL:latest" \
      python /app/extract_files.py "/input/$filename" "/output/"

    end_time=$(date +%s)
    duration=$((end_time - start_time))

    echo "$filename,$duration" >> $OUTPUT_CSV
done

# 7. 上? CSV 到 S3
aws s3 cp $OUTPUT_CSV $S3_OUTPUT_PATH

echo "解?完成，?果已上?到 S3 output 文件?"
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