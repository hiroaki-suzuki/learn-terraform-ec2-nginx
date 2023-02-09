terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider aws {
  region = "ap-northeast-1"
}

variable "vpc_cidr_block" {
  description = "vpc cidr"
  default = "172.16.0.0/16"
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block
  enable_dns_hostnames = true

  tags = {
    Name = "hs-terra-ec2-vpc"
  }
}