# Default Host Management Configuration is region wide

# SSM IAM Role
resource "aws_iam_role" "ssm_role" {
  name = "${local.config.project.name}-ssm-role"
  path = "/service-role/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ssm.amazonaws.com"
        }
      },
    ]
  })
}

# Attach the AmazonSSMManagedEC2InstanceDefaultPolicy policy to the SSM role
resource "aws_iam_role_policy_attachment" "ssm_role_default_policy_attachment" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedEC2InstanceDefaultPolicy"
}

# https://docs.aws.amazon.com/systems-manager/latest/userguide/setup-instance-permissions.html#instance-profile-policies-overview
resource "aws_iam_role_policy_attachment" "ssm_role_cloudwatch_agent" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Needed if vpc endpoints are used for SSM (private subnets)
# https://docs.aws.amazon.com/systems-manager/latest/userguide/setup-instance-permissions.html
data "aws_iam_policy_document" "ssm_s3_bucket_access" {
  statement {
    actions = [
      "s3:GetObject"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:s3:::aws-ssm-${local.config.env.region}/*",
      "arn:aws:s3:::aws-windows-downloads-${local.config.env.region}/*",
      "arn:aws:s3:::amazon-ssm-${local.config.env.region}/*",
      "arn:aws:s3:::amazon-ssm-packages-${local.config.env.region}/*",
      "arn:aws:s3:::us-${local.config.env.region}-birdwatcher-prod/*",
      "arn:aws:s3:::aws-ssm-distributor-file-${local.config.env.region}/*",
      "arn:aws:s3:::aws-ssm-document-attachments-${local.config.env.region}/*",
      "arn:aws:s3:::patch-baseline-snapshot-${local.config.env.region}/*"
    ]
  }
  # if custom bucket used
  #   statement {
  #     effect = "Allow"
  #     actions = [
  #       "s3:GetObject",
  #       "s3:PutObject",
  #       "s3:PutObjectAcl",
  #       "s3:GetEncryptionConfiguration"
  #     ]
  #     resources = [
  #       "arn:aws:s3:::amzn-s3-demo-bucket/*",
  #       "arn:aws:s3:::amzn-s3-demo-bucket"
  #     ]
  #   }
}

resource "aws_iam_role_policy" "ssm_role_s3_bucket_access_policy" {
  name   = "${local.config.project.name}-ssm-role-s3-bucket-access"
  role   = aws_iam_role.ssm_role.id
  policy = data.aws_iam_policy_document.ssm_s3_bucket_access.json
}


resource "aws_ssm_service_setting" "ssm_role_setting" {
  setting_id    = "arn:aws:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:servicesetting/ssm/managed-instance/default-ec2-instance-management-role"
  setting_value = "service-role/${aws_iam_role.ssm_role.name}"
}