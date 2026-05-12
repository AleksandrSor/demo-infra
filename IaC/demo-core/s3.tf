# 1. Create an S3 bucket for Terraform state storage
resource "aws_s3_bucket" "tf_state" {
  bucket           = "tf-state-${local.config.project.name}-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
  bucket_namespace = "account-regional"

  lifecycle {
    # for test purposes, we allow the bucket to be destroyed when the stack is deleted. In production, you may want to set this to true to prevent accidental deletion of the state bucket.
    prevent_destroy = false
  }
}

# 2. Enable versioning to recover older state versions
resource "aws_s3_bucket_versioning" "tf_state_versioning" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 3. Configure server-side encryption using the KMS key created in kms.tf
resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state_encryption" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_alias.tf_state.target_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# 4. Explicitly block all public access
resource "aws_s3_bucket_public_access_block" "tf_state_public_access" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 5. Configure Lifecycle Policy
resource "aws_s3_bucket_lifecycle_configuration" "tf_state_lifecycle" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    id     = "transition-old-versions-to-ia"
    status = "Enabled"

    # Rule applies to noncurrent (previous) versions
    noncurrent_version_transition {
      noncurrent_days = 30 # Days after becoming noncurrent
      storage_class   = "STANDARD_IA"
    }

    # Optional: Delete old versions after X days
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# 6. Create an IAM policy document for the Terraform execution role to access the S3 bucket
data "aws_iam_policy_document" "tf_user_role_s3_access" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.tf_execution_role.arn]
    }

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.tf_state.arn
    ]
  }
  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.tf_execution_role.arn]
    }

    actions = [
      "s3:PutObject",
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.tf_state.arn}/*",
    ]
  }
  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.tf_execution_role.arn]
    }

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]

    resources = [
      "${aws_s3_bucket.tf_state.arn}/*.tflock",
    ]
  }
}

# 7. Attach the bucket policy to allow the Terraform execution role to access the S3 bucket
resource "aws_s3_bucket_policy" "tf_user_role_access" {
  bucket = aws_s3_bucket.tf_state.id
  policy = data.aws_iam_policy_document.tf_user_role_s3_access.json
}