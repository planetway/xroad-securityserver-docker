data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_vpc" "this" {
  state = "available"
}

data "aws_subnet_ids" "db" {
  vpc_id = data.aws_vpc.this.id
  // We have tagged the database subnets as follows
  filter {
    name   = "tag:service"
    values = ["database"]
  }
}

data "aws_subnet_ids" "private" {
  vpc_id = data.aws_vpc.this.id
  // We have tagged the private subnets as follows
  filter {
    name   = "tag:service"
    values = ["application"]
  }
}

data "aws_subnet_ids" "public" {
  vpc_id = data.aws_vpc.this.id
  // We have tagged the public subnets as follows
  filter {
    name   = "tag:service"
    values = ["public"]
  }
}
