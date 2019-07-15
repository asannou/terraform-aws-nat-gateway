variable "region" {
  type = "string"
}

variable "vpc_id" {
  type = "string"
}

variable "cidr_block" {
  type = "string"
}

provider "aws" {
  region = "${var.region}"
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "nat" {
  source = "github.com/asannou/terraform-aws-nat-gateway"
  vpc_id = "${var.vpc_id}"
  availability_zones = ["${data.aws_availability_zones.available.names}"]
  cidr_block = "${var.cidr_block}"
}

output "nat_gateway_ids" {
  value = "${module.nat.nat_gateway_ids}"
}

