resource "aws_vpc" "main" {
  cidr_block = local.config.network.vpc_cidr
  tags       = { Name = "${local.config.project.name}-vpc" }
}

resource "aws_vpc_ipv4_cidr_block_association" "secondary_cidr" {
  vpc_id     = aws_vpc.main.id
  count =  coalesce(try(local.config.network.vpc_secondary_cidr, ""), "") != "" ? 1 : 0
  cidr_block = local.config.network.vpc_secondary_cidr
}
