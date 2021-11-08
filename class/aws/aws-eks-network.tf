# aws-eks-network.tf

resource "aws_vpc" "example" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "eks-example"
  }
}

resource "aws_subnet" "example1" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "eks-example"
  }
}

resource "aws_subnet" "example2" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "eks-example"
  }
}

resource "aws_subnet" "example3" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.3.0/24"

  tags = {
    Name = "eks-example"
  }
}
