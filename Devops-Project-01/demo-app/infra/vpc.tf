resource "aws_vpc" "vpc_name" {
  cidr_block = "10.0.0.0/24"
  tags = {
    "Name" = "dev_vpc"
  }
}


resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.vpc_name.id
  cidr_block = "10.0.0.0/25"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "Public Subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.vpc_name.id
  cidr_block = "10.0.0.128/25"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "Private Subnet"
  }
}



resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_name.id

  tags = {
    "Name" = "dev-igw"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc_name.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    "Name" = "Public Route Table"
  }
  
}

resource "aws_route_table_association" "public_route_table_association" {
  subnet_id = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_eip" "eip-add" {
  domain = "vpc"
   tags = {
    Name = "nat-eip"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.eip-add.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "nat-gateway"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc_name.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "private-route-${terraform.workspace}"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}