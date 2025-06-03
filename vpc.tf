# VPC Setup
resource "aws_vpc" "gpu_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "GPU-Practice-VPC"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.gpu_vpc.id
  tags = {
    Name = "Main-IGW-GPU-Practice"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.gpu_vpc.id
  cidr_block              = var.public_subnet
  map_public_ip_on_launch = true
  availability_zone       = "${var.region}a"
  tags = {
    Name = "Public-Subnet-GPU-Practice"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.gpu_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public-RouteTable-GPU-Practice"
  }
}

resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}
