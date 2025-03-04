# VPC���쐬����
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "${var.test_prefix}-vpc"
  }
}

# �C���^�[�l�b�g�Q�[�g�E�F�C���쐬����
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.test_prefix}-igw"
  }
}

# ���p�\�ȃA�x�C���r���e�B�]�[�����擾����
data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "region-name"
    values = ["ap-northeast-1"]
  }
}

locals {
  subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]
}

# �T�u�l�b�g���쐬����
resource "aws_subnet" "subnet" {
  count             = length(data.aws_availability_zones.available.names)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(local.subnets, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  tags = {
    Name = "${var.test_prefix}-subnet-${count.index}-${element(data.aws_availability_zones.available.names, count.index)}"
  }
}

# ���[�g�e�[�u�����쐬����
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${var.test_prefix}-route-atable"
  }
}

# �T�u�l�b�g�Ƀ��[�g�e�[�u�����֘A�t����
resource "aws_route_table_association" "subnet_association" {
  count          = length(aws_subnet.subnet)
  subnet_id      = element(aws_subnet.subnet.*.id, count.index)
  route_table_id = aws_route_table.rt.id
}

# SSH�A�N�Z�X�p�̃Z�L�����e�B�O���[�v���쐬����
resource "aws_security_group" "ssh_access" {
  name        = "${var.test_prefix}-ssh-sg"
  description = "�|�[�g22��SSH�A�N�Z�X��������Z�L�����e�B�O���[�v"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.test_prefix}-ssh-sg"
  }
}