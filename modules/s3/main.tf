# terraform {
#   required_version = ">= 1.0"
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~> 5.0"
#     }
#   }
# }

resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name

  tags = merge(
    var.tags,
    {
      Name        = var.bucket_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

# # Versionamento
# resource "aws_s3_bucket_versioning" "this" {
#   bucket = aws_s3_bucket.this.id

#   versioning_configuration {
#     status     = var.versioning_enabled ? "Enabled" : "Suspended"
#     mfa_delete = var.environment == "prod" ? "Enabled" : "Disabled"
#   }
# }

# # Criptografia
# resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
#   count  = var.enable_server_side_encryption ? 1 : 0
#   bucket = aws_s3_bucket.this.id

#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = var.encryption_algorithm
#     }
#     bucket_key_enabled = true
#   }
# }

# # Block Public Access
# resource "aws_s3_bucket_public_access_block" "this" {
#   bucket = aws_s3_bucket.this.id

#   block_public_acls       = var.block_public_acls
#   block_public_policy     = var.block_public_policy
#   ignore_public_acls      = var.ignore_public_acls
#   restrict_public_buckets = var.restrict_public_buckets
# }

# # ACL
# resource "aws_s3_bucket_acl" "this" {
#   bucket = aws_s3_bucket.this.id
#   acl    = "private"

#   depends_on = [aws_s3_bucket_public_access_block.this]
# }

# # Logging
# resource "aws_s3_bucket_logging" "this" {
#   count         = var.enable_logging ? 1 : 0
#   bucket        = aws_s3_bucket.this.id
#   target_bucket = aws_s3_bucket.logs[0].id
#   target_prefix = "logs/"
# }

# resource "aws_s3_bucket" "logs" {
#   count  = var.enable_logging ? 1 : 0
#   bucket = "${var.bucket_name}-logs"

#   tags = merge(
#     var.tags,
#     {
#       Name        = "${var.bucket_name}-logs"
#       Environment = var.environment
#       ManagedBy   = "Terraform"
#     }
#   )
# }

# resource "aws_s3_bucket_public_access_block" "logs" {
#   count  = var.enable_logging ? 1 : 0
#   bucket = aws_s3_bucket.logs[0].id

#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }

# # Lifecycle Rules
# resource "aws_s3_bucket_lifecycle_configuration" "this" {
#   count  = length(var.lifecycle_rules) > 0 ? 1 : 0
#   bucket = aws_s3_bucket.this.id

#   dynamic "rule" {
#     for_each = var.lifecycle_rules
#     content {
#       id     = "rule-${rule.key}"
#       status = rule.value.enabled ? "Enabled" : "Disabled"
#       filter {
#         prefix = rule.value.prefix
#       }
#       transition {
#         days          = rule.value.days
#         storage_class = rule.value.storage_class
#       }
#     }
#   }
# }
