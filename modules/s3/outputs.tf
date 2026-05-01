output "bucket_id" {
  description = "Nome (ID) do bucket S3"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN do bucket S3"
  value       = aws_s3_bucket.this.arn
}

output "bucket_region" {
  description = "Região do bucket"
  value       = aws_s3_bucket.this.region
}

output "bucket_domain_name" {
  description = "Domain name do bucket"
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

output "versioning_enabled" {
  description = "Status do versionamento"
  value       = var.versioning_enabled
}

output "encryption_enabled" {
  description = "Status da criptografia"
  value       = var.enable_server_side_encryption
}

output "logs_bucket_id" {
  description = "Nome (ID) do bucket de logs"
  value       = try(aws_s3_bucket.logs[0].id, null)
}
