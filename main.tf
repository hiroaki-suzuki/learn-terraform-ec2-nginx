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
  ingress {
    from_port   = 80
    to_port     = 80
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
    Name = join("-", [local.name_prefix, "public", "sg"])
  }
}

resource "aws_iam_role" "ec2_role" {
  name               = join("-", [local.name_prefix, "ec2", "role"])
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/EC2InstanceConnect"
  ]
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = join("-", [local.name_prefix, "ec2", "profile"])
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "nginx" {
  ami                         = "ami-0bba69335379e17f8"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_a.id
  vpc_security_group_ids      = [aws_security_group.public_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.name
  user_data                   = file("user-data-ec2.sh")

  tags = {
    Name = join("-", [local.name_prefix, "nginx"])
  }
}