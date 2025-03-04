variable "test_prefix" {
  description = "バッチテスト環境のプレフィックス"
  type        = string
}

variable "key_pair_name" {
  description = "SSHキーペアの名前"
  type        = string
}

variable "ami_id" {
  description = "EC2インスタンスのAMI ID"
  type        = string
}

variable "instance_type" {
  description = "EC2インスタンスのタイプ"
  type        = string
  default     = "t2.micro"
}

variable "subnet_id" {
  description = "EC2インスタンスを起動するサブネットID"
  type        = string
}

variable "security_group" {
  description = "EC2インスタンスに割り当てるセキュリティグループ"
  type        = string
}