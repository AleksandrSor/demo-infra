resource "aws_security_group" "alb_shared_backend" {
  name        = "${local.config.project.name}-alb-shared-backend"
  description = "ALB Load Balancer Controller Shared Backend"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.config.project.name}-alb-shared-backend-sg"
  }
}

# ALB Backend <-> Pods rules
resource "aws_vpc_security_group_ingress_rule" "alb_shared_allow_pods" {
  security_group_id            = aws_security_group.alb_shared_backend.id
  referenced_security_group_id = aws_security_group.eks_pods.id

  ip_protocol = "-1"

  description = "Allow all from Pods"
}

resource "aws_vpc_security_group_egress_rule" "alb_shared_allow_pods" {
  security_group_id            = aws_security_group.alb_shared_backend.id
  referenced_security_group_id = aws_security_group.eks_pods.id

  ip_protocol = "-1"

  description = "Allow all to Pods"
}

output "alb_controller_shared_backend_sg_id" {
  value       = aws_security_group.alb_shared_backend.id
  description = "ID of the security group for ALB Load Balancer Controller Shared Backend"
}