resource "aws_subnet" "node_subnet" {

  vpc_id = aws_vpc.main.id

  for_each          = local.config.network.node_subnets
  availability_zone = each.value.az

  cidr_block      = each.value.cidr
  ipv6_cidr_block = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, index(keys(local.config.network.node_subnets), each.key))

  private_dns_hostname_type_on_launch = "resource-name"
  map_public_ip_on_launch             = true # TODO: make it configurable to support private subnets
  assign_ipv6_address_on_creation     = true

  tags = {
    Name                                              = "${local.config.project.name}-${each.key}"
    "kubernetes.io/cluster/${local.eks_cluster_name}" = "owned"
    "kubernetes.io/role/cni"                          = "0"
  }
}

resource "aws_route_table_association" "node_subnet_association" {
  for_each       = local.config.network.node_subnets
  subnet_id      = aws_subnet.node_subnet[each.key].id
  route_table_id = aws_route_table.public.id # TODO: make it configurable to support private subnets
}

resource "aws_network_acl" "node_subnet_acl" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.config.project.name}-node-subnet-acl"
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 1
    action     = "deny"
    from_port  = 1
    to_port    = 52
    cidr_block = "0.0.0.0/0"
  }

  ingress {
    protocol        = "tcp"
    rule_no         = 11
    action          = "deny"
    from_port       = 1
    to_port         = 52
    ipv6_cidr_block = "::/0"
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 2
    action     = "deny"
    from_port  = 54
    to_port    = 442
    cidr_block = "0.0.0.0/0"
  }

  ingress {
    protocol        = "tcp"
    rule_no         = 12
    action          = "deny"
    from_port       = 54
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
    to_port    = 52
    cidr_block = "0.0.0.0/0"
  }

  ingress {
    protocol        = "udp"
    rule_no         = 14
    action          = "deny"
    from_port       = 1
    to_port         = 52
    ipv6_cidr_block = "::/0"
  }

  ingress {
    protocol   = "udp"
    rule_no    = 5
    action     = "deny"
    from_port  = 54
    to_port    = 442
    cidr_block = "0.0.0.0/0"
  }

  ingress {
    protocol        = "udp"
    rule_no         = 15
    action          = "deny"
    from_port       = 54
    to_port         = 442
    ipv6_cidr_block = "::/0"
  }

  ingress {
    protocol   = "udp"
    rule_no    = 6
    action     = "deny"
    from_port  = 444
    to_port    = 1023
    cidr_block = "0.0.0.0/0"
  }

  ingress {
    protocol        = "udp"
    rule_no         = 16
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

resource "aws_network_acl_association" "node_subnet_acl_association" {
  for_each       = local.config.network.node_subnets
  subnet_id      = aws_subnet.node_subnet[each.key].id
  network_acl_id = aws_network_acl.node_subnet_acl.id
}

output "node_subnet_ids" {
  value = [for s in aws_subnet.node_subnet : s.id]
}
