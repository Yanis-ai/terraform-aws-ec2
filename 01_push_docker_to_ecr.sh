#!/bin/bash
set -euo pipefail

# �ϐ��̐ݒ�
REPO_NAME="batch-test-repo"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="ap-northeast-1"
ECR_URL="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}"

# Docker�C���[�W�̃r���h
docker build -t "${REPO_NAME}" .

# AWS ECR�ւ̃��O�C��
aws ecr get-login-password --region "${REGION}" | docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

# Docker�C���[�W�Ƀ^�O��t����
docker tag "${REPO_NAME}:latest" "${ECR_URL}:latest"

# Docker�C���[�W��ECR�Ƀv�b�V������
docker push "${ECR_URL}:latest"