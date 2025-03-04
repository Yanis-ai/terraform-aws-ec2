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
# locals {
#   install_docker_pull_image_script = <<EOT
# #!/bin/bash
# # �V�X�e�����X�V
# sudo apt-get update -y
# # �K�v�Ȉˑ��֌W���C���X�g�[��
# sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
# # Docker�̌���GPG����ǉ�
# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
# # Docker�̃��|�W�g����ǉ�
# sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
# # �p�b�P�[�W���X�g���X�V
# sudo apt-get update -y
# # Docker���C���X�g�[��
# sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# # AWS ECR�Ƀ��O�C��
# account_id=$(aws sts get-caller-identity --query Account --output text)
# aws ecr get-login-password --region "ap-northeast-1" | sudo docker login --username AWS --password-stdin $account_id.dkr.ecr.ap-northeast-1.amazonaws.com

# # Docker�C���[�W���v��
# sudo docker pull $account_id.dkr.ecr.ap-northeast-1.amazonaws.com/batch-test-repo:latest
# EOT
# }
locals {
  install_docker_pull_image_script = <<EOT
#!/bin/bash
set -e

# ��??��
S3_BUCKET_NAME="${module.s3_bucket.bucket_name}"
S3_INPUT_PATH="s3://$S3_BUCKET_NAME/input/"
S3_OUTPUT_PATH="s3://$S3_BUCKET_NAME/output/"
LOCAL_INPUT_DIR="/data/input"
LOCAL_OUTPUT_DIR="/data/output"
OUTPUT_CSV="$LOCAL_OUTPUT_DIR/output.csv"

# 1. �X�V�n?������K�v�H��
sudo apt-get update -y
sudo apt-get install -y awscli tar jq

# 2. ?���{�n��?
mkdir -p $LOCAL_INPUT_DIR $LOCAL_OUTPUT_DIR

# 3. ��? S3 ��I���L .tar.gz ����
aws s3 cp $S3_INPUT_PATH $LOCAL_INPUT_DIR --recursive --exclude "*" --include "*.tar.gz"

# 4. ���� Docker
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# 5. �o? AWS ECR ��f�� Docker ?��
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="ap-northeast-1"
ECR_URL="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/batch-test-repo"

aws ecr get-login-password --region "$REGION" | sudo docker login --username AWS --password-stdin "$ECR_URL"
sudo docker pull "$ECR_URL:latest"

# 6. ?�s Docker �e��?�s��?�C��????
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

# 7. ��? CSV �� S3
aws s3 cp $OUTPUT_CSV $S3_OUTPUT_PATH

echo "��?�����C?�ʛߏ�?�� S3 output ����?"
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