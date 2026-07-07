resource "aws_subnet" "alb_subnet" {

  vpc_id = aws_vpc.main.id

  for_each                            = local.config.network.alb_subnets
  cidr_block                          = each.value.cidr
  ipv6_cidr_block                     = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, index(keys(local.config.network.alb_subnets), each.key) + length(keys(local.config.network.node_subnets)))
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

resource "aws_network_acl" "alb_subnet_acl" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.config.project.name}-alb-subnet-acl"
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 1
    action     = "deny"
    from_port  = 1
    to_port    = 79
    cidr_block = "0.0.0.0/0"
  }

  ingress {
    protocol        = "tcp"
    rule_no         = 11
    action          = "deny"
    from_port       = 1
    to_port         = 79
    ipv6_cidr_block = "::/0"
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 2
    action     = "deny"
    from_port  = 81
    to_port    = 442
    cidr_block = "0.0.0.0/0"
  }

  ingress {
    protocol        = "tcp"
    rule_no         = 12
    action          = "deny"
    from_port       = 81
    to_port         = 442
    ipv6_cidr_block = "::/0"
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 3
    action     = "deny"
    from_port  = 444
    to_port    = 1023
    cidr_block = "0.0.0.0/0"
  }

  ingress {
    protocol        = "tcp"
    rule_no         = 13
    action          = "deny"
    from_port       = 444
    to_port         = 1023
    ipv6_cidr_block = "::/0"
  }

  ingress {
    protocol   = "udp"
    rule_no    = 4
    action     = "deny"
    from_port  = 1
    to_port    = 442
    cidr_block = "0.0.0.0/0"
  }

  ingress {
    protocol        = "udp"
    rule_no         = 14
    action          = "deny"
    from_port       = 1
    to_port         = 442
    ipv6_cidr_block = "::/0"
  }

  ingress {
    protocol   = "udp"
    rule_no    = 5
    action     = "deny"
    from_port  = 444
    to_port    = 1023
    cidr_block = "0.0.0.0/0"
  }

  ingress {
    protocol        = "udp"
    rule_no         = 15
    action          = "deny"
    from_port       = 444
    to_port         = 1023
    ipv6_cidr_block = "::/0"
  }

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol        = -1
    rule_no         = 101
    action          = "allow"
    ipv6_cidr_block = "::/0"
    from_port       = 0
    to_port         = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol        = -1
    rule_no         = 101
    action          = "allow"
    ipv6_cidr_block = "::/0"
    from_port       = 0
    to_port         = 0
  }
}

resource "aws_network_acl_association" "alb_subnet_acl_association" {
  for_each       = local.config.network.alb_subnets
  subnet_id      = aws_subnet.alb_subnet[each.key].id
  network_acl_id = aws_network_acl.alb_subnet_acl.id
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