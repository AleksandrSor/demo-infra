resource "aws_subnet" "alb_subnet" {

  vpc_id = aws_vpc.main.id

  for_each                            = local.config.network.alb_subnets
  cidr_block                          = each.value.cidr
  availability_zone                   = each.value.az
  private_dns_hostname_type_on_launch = "resource-name"

  tags = {
    Name                                              = "${local.config.project.name}-${each.key}"
    "kubernetes.io/role/elb"                          = "1"
    "kubernetes.io/cluster/${local.eks_cluster_name}" = "owned"
  }
}

resource "aws_route_table_association" "alb_subnet_association" {
  for_each       = local.config.network.alb_subnets
  subnet_id      = aws_subnet.alb_subnet[each.key].id
  route_table_id = aws_route_table.public.id # TODO: make it configurable to support private subnets
}

resource "aws_subnet" "nlb_subnet" {

  vpc_id = aws_vpc.main.id

  for_each                            = local.config.network.nlb_subnets
  cidr_block                          = each.value.cidr
  availability_zone                   = each.value.az
  private_dns_hostname_type_on_launch = "resource-name"

  tags = {
    Name                                              = "${local.config.project.name}-${each.key}"
    "kubernetes.io/role/internal-elb"                 = "1"
    "kubernetes.io/cluster/${local.eks_cluster_name}" = "owned"
  }
}

resource "aws_route_table_association" "nlb_subnet_association" {
  for_each       = local.config.network.nlb_subnets
  subnet_id      = aws_subnet.nlb_subnet[each.key].id
  route_table_id = aws_route_table.private.id # TODO: make it configurable to support private subnets
}