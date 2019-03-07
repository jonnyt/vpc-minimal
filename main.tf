terraform {
  required_version = ">= 0.11.11"
}

# ---------------------------------------------------------------------------------------------------------------------
# Create the VPC
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_vpc" "vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags {
    Name        = "${var.vpc_name}"
    Terraform   = "true"
    Environment = "${var.env}"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Subnets: For this we are dividing an assumed /24 into 4 equal sizes, this can be changed depending on use
# case.
# TODO: parameterized to ensure DEV/TEST uses single AZ
# ---------------------------------------------------------------------------------------------------------------------

locals {
  pub-net-1-cidr  = "${cidrsubnet(var.vpc_cidr, 2, 0)}"
  pub-net-2-cidr  = "${cidrsubnet(var.vpc_cidr, 2, 1)}"
  priv-net-1-cidr = "${cidrsubnet(var.vpc_cidr, 2, 2)}"
  priv-net-2-cidr = "${cidrsubnet(var.vpc_cidr, 2, 3)}"
}

resource "aws_subnet" "pub-net-1" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "${local.pub-net-1-cidr}"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags {
    Name = "pub-net-1"
  }

  depends_on = ["aws_vpc.vpc"]
}

resource "aws_subnet" "pub-net-2" {
  #count = "${var.env=="dev" ? 0 : 1}"
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "${local.pub-net-2-cidr}"
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = true

  tags {
    Name = "pub-net-2"
  }

  depends_on = ["aws_vpc.vpc"]
}

resource "aws_subnet" "priv-net-1" {
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "${local.priv-net-1-cidr}"
  availability_zone = "${var.region}a"

  tags {
    Name = "priv-net-1"
  }

  depends_on = ["aws_vpc.vpc"]
}

resource "aws_subnet" "priv-net-2" {
  #count = "${var.env=="dev" ? 0 : 1}"
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "${local.priv-net-2-cidr}"
  availability_zone = "${var.region}b"

  tags {
    Name = "priv-net-2"
  }

  depends_on = ["aws_vpc.vpc"]
}

# ---------------------------------------------------------------------------------------------------------------------
# IGW
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name = "igw.${var.vpc_name}"
  }

  depends_on = ["aws_vpc.vpc"]
}

# ---------------------------------------------------------------------------------------------------------------------
# Routes and route tables
# Explicitly associate each private net with own custom route table, add route for specific NAT GW
# Explicitly associate both public nets with single custom route table, add route for IGW
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_route_table" "priv-net-1" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name = "rt.${var.vpc_name}.priv-net-1"
  }

  depends_on = ["aws_vpc.vpc", "aws_nat_gateway.ngw1"]
}

resource "aws_route_table_association" "priv-net-1" {
  subnet_id      = "${aws_subnet.priv-net-1.id}"
  route_table_id = "${aws_route_table.priv-net-1.id}"
  depends_on     = ["aws_route_table.priv-net-1"]
}

resource "aws_route_table" "priv-net-2" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name = "rt.${var.vpc_name}.priv-net-2"
  }

  depends_on = ["aws_vpc.vpc", "aws_nat_gateway.ngw1"]
}

resource "aws_route_table_association" "priv-net-2" {
  subnet_id      = "${aws_subnet.priv-net-2.id}"
  route_table_id = "${aws_route_table.priv-net-2.id}"
  depends_on     = ["aws_route_table.priv-net-2"]
}

# Custom route table for public nets
resource "aws_route_table" "pub-nets" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name = "rt.${var.vpc_name}.pub-nets"
  }

  depends_on = ["aws_vpc.vpc", "aws_internet_gateway.igw"]
}

resource "aws_route_table_association" "pub-net-1" {
  subnet_id      = "${aws_subnet.pub-net-1.id}"
  route_table_id = "${aws_route_table.pub-nets.id}"
  depends_on     = ["aws_route_table.pub-nets"]
}

resource "aws_route_table_association" "pub-net-2" {
  subnet_id      = "${aws_subnet.pub-net-2.id}"
  route_table_id = "${aws_route_table.pub-nets.id}"
  depends_on     = ["aws_route_table.pub-nets"]
}

resource "aws_route" "pub_default" {
  route_table_id         = "${aws_route_table.pub-nets.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.igw.id}"
}

# ---------------------------------------------------------------------------------------------------------------------
# NAT gateways
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_nat_gateway" "ngw1" {
  allocation_id = "${aws_eip.ngw1.id}"
  subnet_id     = "${aws_subnet.pub-net-1.id}"

  tags {
    Name = "ngw1"
  }

  depends_on = ["aws_vpc.vpc", "aws_eip.ngw1", "aws_subnet.pub-net-1"]
}

resource "aws_nat_gateway" "ngw2" {
  count         = "${var.env=="dev" ? 0 : 1}"
  allocation_id = "${aws_eip.ngw2.id}"
  subnet_id     = "${aws_subnet.pub-net-2.id}"

  tags {
    Name = "ngw2"
  }

  depends_on = ["aws_vpc.vpc", "aws_eip.ngw2", "aws_subnet.pub-net-2"]
}

# ---------------------------------------------------------------------------------------------------------------------
# EIPs for NAT gateways
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_eip" "ngw1" {
  vpc = true
}

resource "aws_eip" "ngw2" {
  count = "${var.env=="dev" ? 0 : 1}"
  vpc   = true
}
