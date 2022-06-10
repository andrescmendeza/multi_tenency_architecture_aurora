
# Fetch AZs in the current region
data "aws_availability_zones" "available" {
}

##------------------------
## The application VPC
##------------------------

resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name        = "feature"
    Environment = "feature"
  }
}

##------------------------
## Subnets
##------------------------

# Create var.az_count private subnets, each in a different AZ
resource "aws_subnet" "private" {
  count             = var.vpc_private_az_count
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.vpc.id
  tags = {
    Name        = "feature-private"
    Environment = "feature"
    Type        = "private"
  }
}

# Create var.az_count public subnets, each in a different AZ
resource "aws_subnet" "public" {
  count                   = var.vpc_public_az_count
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, 8, var.vpc_public_az_count + count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = true
  tags = {
    Name        = "feature-public"
    Environment = "feature"
    Type        = "public"
  }
}

##------------------------
## Internet Gateway for the VPC
##------------------------

# Internet Gateway for the public subnet
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name        = "feature-ig"
    Environment = "feature"
    Resource    = "internet gateway"
  }
}

# Route the public subnet traffic through the IGW
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

##------------------------
## NAT Gateway for the Private Subnets in the VPC
##------------------------
# Create a NAT gateway with an Elastic IP for each private subnet to get internet connectivity
resource "aws_eip" "gw" {
  count      = var.vpc_private_az_count
  vpc        = true
  depends_on = [aws_internet_gateway.gw]
  tags = {
    Name        = "feature-NAT"
    Environment = "feature"
    Resource    = "NAT gateway"
  }
}

resource "aws_nat_gateway" "gw" {
  count         = var.vpc_private_az_count
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  allocation_id = element(aws_eip.gw.*.id, count.index)
  tags = {
    Name        = "feature-NAT"
    Environment = "feature"
    Resource    = "NAT gateway"
  }
}

# Create a new route table for the private subnets, make it route non-local traffic through the NAT gateway to the internet
resource "aws_route_table" "private" {
  count  = var.vpc_private_az_count
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.gw.*.id, count.index)
  }
  tags = {
    Name        = "feature-private"
    Environment = "feature"
    Resource    = "private"
  }
}

# Explicitly associate the newly created route tables to the private subnets (so they don't default to the main route table)
resource "aws_route_table_association" "private" {
  count          = var.vpc_private_az_count
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}