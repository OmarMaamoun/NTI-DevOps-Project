#Creating VPC
resource "aws_vpc" "main" {
  cidr_block  =var.vpc_cider
  instance_tenancy = "default"

  tags = {
    Name = "${var.environment}-vpc"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}
#Creating Public subnet 
resource "aws_subnet" "public_az2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_az2_subnet
  availability_zone = var.az2

  tags = {
     Name = "${var.environment}-public-az2-"
     "kubernetes.io/cluster/${var.cluster_name}" = "shared"
     "kubernetes.io/role/elb"                  = "1"
     "kubernetes.io/role/public"               = "1"
  }
}
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet
  availability_zone = var.az1

  tags = {
     Name = "${var.environment}-public-"
     "kubernetes.io/cluster/${var.cluster_name}" = "shared"
     "kubernetes.io/role/elb"                  = "1"
     "kubernetes.io/role/public"               = "1"
  }
}
#Creating Private subnet 
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet
  availability_zone = var.az1

  tags = {
    Name = "${var.environment}-private-"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"         = "1"
  }
}
resource "aws_subnet" "private_az2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_az2_subnet
  availability_zone = var.az2

  tags = {
    Name = "${var.environment}-private-az2"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"         = "1"
  }
}

#Creating Internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-igw"
  }
}
#Create Route table
resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
     Name = "${var.environment}-rt"
  }
}
# Private route table for both AZs
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "${var.environment}-private-rt"
  }
}
# Associate both private subnets with this route table
resource "aws_route_table_association" "private_az1" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private_rt.id
}
resource "aws_route_table_association" "private_az2" {
  subnet_id      = aws_subnet.private_az2.id
  route_table_id = aws_route_table.private_rt.id
}

#Create association for the route table
resource "aws_route_table_association" "public_az1_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public-rt.id
}
resource "aws_route_table_association" "public_az2_assoc" {
  subnet_id      = aws_subnet.public_az2.id
  route_table_id = aws_route_table.public-rt.id
}
#Create Security group
resource "aws_security_group" "dev-sg" {
  name        = "dev-SG"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.main.id
  ingress{
    from_port        = 22
    to_port          = 22
    protocol         = "TCP"
    cidr_blocks      = var.cidr_blocks
  }
  ingress{
    from_port        = 8080
    to_port          = 8080
    protocol         = "TCP"
    cidr_blocks      = var.cidr_blocks
  }
  ingress{
    from_port        = 9000
    to_port          = 9000
    protocol         = "TCP"
    cidr_blocks      = var.cidr_blocks
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = var.cidr_blocks
  }
  tags = {
    Name = "${var.environment}-SG"
  }
}

#Create RDS SG 
resource "aws_security_group" "rds-sg" {
  name        = "rds-SG"
  description = "RDS-SG"
  vpc_id      = aws_vpc.main.id
   ingress{
    from_port        = 5432
    to_port          = 5432
    protocol         = "TCP"
    cidr_blocks      = var.cidr_blocks
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = var.cidr_blocks
  }
  tags = {
    Name = "${var.environment}-RDS-SG"
  }
}
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.environment}-rds-subnet-group"
  subnet_ids = [aws_subnet.private.id, aws_subnet.private_az2.id]

  tags = {
    Name = "${var.environment}-rds-subnet-group"
  }
}

resource "aws_eip" "dev-eip" {
  domain           = "vpc"
  network_border_group = "eu-north-1"
  tags={
    Name="${var.environment}-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.dev-eip.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "${var.environment}-NAT-1"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}