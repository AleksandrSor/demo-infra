resource "aws_subnet" "node_subnet" {

  vpc_id = aws_vpc.main.id

  for_each                            = local.config.network.node_subnets
  cidr_block                          = each.value.cidr
  availability_zone                   = each.value.az
  private_dns_hostname_type_on_launch = "resource-name"

  tags = {
    Name = "${local.config.project.name}-node-subnet-${each.key}"
  }
}

resource "aws_route_table_association" "node_subnet_association" {
  for_each       = local.config.network.node_subnets
  subnet_id      = aws_subnet.node_subnet[each.key].id
  route_table_id = aws_route_table.public.id # TODO: make it configurable to support private subnets
}