#!/bin/bash
set -euo pipefail

# 変数の設定
REPO_NAME="batch-test-repo"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="ap-northeast-1"
ECR_URL="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}"

# Dockerイメージのビルド
docker build -t "${REPO_NAME}" .

# AWS ECRへのログイン
aws ecr get-login-password --region "${REGION}" | docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

# Dockerイメージにタグを付ける
docker tag "${REPO_NAME}:latest" "${ECR_URL}:latest"

# DockerイメージをECRにプッシュする
docker push "${ECR_URL}:latest"