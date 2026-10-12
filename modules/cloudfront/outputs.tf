# ## OUTPUTS ##
output "distribution_id" {
  value = aws_cloudfront_distribution.cloudfront.id
}
output "s3_bucket_website_endpoint" {
  value = aws_s3_bucket_website_configuration.website_endpoint.website_endpoint
}
output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.cloudfront.domain_name
}
output "cloudfront_domain_arn" {
  value = aws_cloudfront_distribution.cloudfront.arn
}