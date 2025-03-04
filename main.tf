provider "aws" {
  region = "ap-northeast-1"
}

variable "test_prefix" {
  description = "バッチテスト環境のプレフィックス"
  type        = string
  default     = "batch-test"
}

variable "bucket_name_prefix" {
  description = "S3バケット名のプレフィックス"
  default     = "batch-test-bucket"
}

variable "key_pair_name" {
  description = "EC2インスタンス用のキーペアの名前"
  type        = string
  default     = "ssh-key-pair"
}

module "vpc" {
  source      = "./modules/vpc"
  test_prefix = var.test_prefix
}

module "s3_bucket" {
  source = "./modules/s3"
  bucket_name_prefix = var.bucket_name_prefix
}

module "ecr_repository" {
  source = "./modules/ecr"
  repository_name = "batch-test-repo"
}

module "ec2_instance" {
  source = "./modules/ec2"
  test_prefix = var.test_prefix
  key_pair_name = var.key_pair_name
  ami_id = "ami-0a290015b99140cd1"   # 実際のAMI IDに置き換えてください
  instance_type = "t2.micro"         # 必要なインスタンスタイプを選択してください
  subnet_id = module.vpc.subnet_ids[0]  # 複数のサブネットがある前提で選択してください
  security_group = module.vpc.security_group_id #先に作成したセキュリティグループを使用
  
}

resource "null_resource" "execute_script" {
  depends_on = [module.s3_bucket]
  provisioner "local-exec" {
    command = "./00_generate_and_upload_script.sh"
  }
}

resource "null_resource" "upload_files" {
  depends_on = [null_resource.execute_script]
  provisioner "local-exec" {
    command = <<EOT
      aws s3 cp ./testfiles/ s3://${module.s3_bucket.bucket_name}/input/ --recursive
      rm -f ./testfiles/*
    EOT
  }
}

resource "null_resource" "push_docker_image" {
  depends_on = [module.ecr_repository]
  provisioner "local-exec" {
    command = "./01_push_docker_to_ecr.sh"
  }
}

output "subnet_id" {
  description = "作成されたサブネットID"
  value       = module.vpc.subnet_ids
}