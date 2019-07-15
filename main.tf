variable "vpc_id" {
  type = "string"
}

variable "availability_zones" {
  type = "list"
}

variable "cidr_block" {
  type = "string"
}

locals {
  count = "${length(var.availability_zones)}"
  newbits = "${ceil(log(local.count, 2))}"
}

resource "aws_subnet" "nat" {
  count = "${local.count}"
  vpc_id = "${var.vpc_id}"
  availability_zone = "${var.availability_zones[count.index]}"
  cidr_block = "${cidrsubnet(var.cidr_block, local.newbits, count.index)}"
  map_public_ip_on_launch = false
  tags = {
    Name = "nat-${var.vpc_id}-${var.availability_zones[count.index]}"
  }
}

resource "aws_nat_gateway" "nat" {
  count = "${local.count}"
  allocation_id = "${aws_eip.nat.*.id[count.index]}"
  subnet_id = "${aws_subnet.nat.*.id[count.index]}"
  tags = {
    Name = "nat-${var.vpc_id}-${var.availability_zones[count.index]}"
  }
}

resource "aws_eip" "nat" {
  count = "${local.count}"
  vpc = true
  tags = {
    Name = "nat-${var.vpc_id}-${var.availability_zones[count.index]}"
  }
}

resource "aws_route_table_association" "nat" {
  count = "${local.count}"
  subnet_id = "${aws_subnet.nat.*.id[count.index]}"
  route_table_id = "${aws_route_table.nat.id}"
}

resource "aws_route_table" "nat" {
  vpc_id = "${var.vpc_id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${data.aws_internet_gateway.vpc.id}"
  }
  tags = {
    Name = "nat-${var.vpc_id}"
  }
}

data "aws_internet_gateway" "vpc" {
  filter {
    name = "attachment.vpc-id"
    values = ["${var.vpc_id}"]
  }
}

output "nat_gateway_ids" {
  value = "${aws_nat_gateway.nat.*.id}"
}

