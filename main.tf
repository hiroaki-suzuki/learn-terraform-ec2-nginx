terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

locals {
  name_prefix = "hs-terra-nginx"
}

variable "vpc_cidr_block" {
  description = "vpc cidr"
  default     = "172.16.0.0/16"
}

variable "subnet_cidr_block" {
  description = "public subnet cidr"
  default     = "172.16.0.0/24"
}

# ネットワーク関連
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true

  tags = {
    Name = join("-", [local.name_prefix, "vpc"])
  }
}

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_cidr_block
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = join("-", [local.name_prefix, "public", "subnet"])
  }
}

resource "aws_internet_gateway" "main-igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = join("-", [local.name_prefix, "igw"])
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main-igw.id
  }

  tags = {
    Name = join("-", [local.name_prefix, "public", "rtb"])
  }
}

resource "aws_route_table_association" "public_subnet_a" {
  route_table_id = aws_route_table.main.id
  subnet_id      = aws_subnet.public_a.id
}

# セキュリティグループ関連
resource "aws_security_group" "public_sg" {
  name   = join("-", [local.name_prefix, "public", "sg"])
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = join("-", [local.name_prefix, "public", "sg"])
  }
}