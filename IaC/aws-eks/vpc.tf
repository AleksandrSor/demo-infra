resource "aws_vpc" "main" {
  cidr_block           = local.config.network.vpc_cidr
  tags                 = { Name = "${local.config.project.name}-vpc" }
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_vpc_ipv4_cidr_block_association" "secondary_cidr" {
  vpc_id = aws_vpc.main.id
  #count      = coalesce(try(local.config.network.vpc_secondary_cidr, ""), "") != "" ? 1 : 0
  cidr_block = local.config.network.vpc_secondary_cidr
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.config.project.name}-igw"
  }
}

resource "aws_default_security_group" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.config.project.name}-main-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "main" {
  security_group_id            = aws_default_security_group.main.id
  referenced_security_group_id = aws_default_security_group.main.id

  ip_protocol = "-1"

  description = "Allow all within the sg"
}

# trivy:ignore:AWS-0104
# it's a default security group, so it ok to allow all outbound traffic
resource "aws_vpc_security_group_egress_rule" "main" {
  security_group_id = aws_default_security_group.main.id

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"

  description = "Allow all outbound traffic"
}

resource "aws_default_route_table" "main" {
  default_route_table_id = aws_vpc.main.default_route_table_id

  tags = {
    Name = "${local.config.project.name}-main-rt"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.config.project.name}-public-rt"
  }

  depends_on = [aws_vpc_ipv4_cidr_block_association.secondary_cidr]
}

resource "aws_route" "internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.config.project.name}-private-rt"
  }

  depends_on = [aws_vpc_ipv4_cidr_block_association.secondary_cidr]
}