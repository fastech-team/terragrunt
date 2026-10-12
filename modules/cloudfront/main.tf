## PROVIDES ##
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.64.0"
    }
  }
}
provider "aws" {
  region = var.region
  alias  = "default"
}
# ACM certificate must be us-east-1 (N. Virginia) for CloudFront
provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}

## DATA SOURCES ##
data "aws_cloudfront_cache_policy" "additional" {
  provider = aws.virginia
  for_each = toset(var.additional_behaviors[*].cache_policy_name)
  name     = each.value
}

data "aws_cloudfront_origin_request_policy" "additional" {
  provider = aws.virginia
  for_each = toset(var.additional_behaviors[*].origin_request_policy_name)
  name     = each.value
}

data "aws_cloudfront_cache_policy" "cache" {
  name = "Managed-CachingOptimized"
}
data "aws_cloudfront_origin_request_policy" "origin_request" {
  name = "Managed-AllViewer"
}
data "aws_acm_certificate" "acm_cert" {
  count    = var.aws_acm_certificate ? 1 : 0
  domain   = "${var.cname}.${var.domain}"
  statuses = ["ISSUED"]
  provider = aws.virginia
}



## LOCAL VALUES ##
locals {
  bucket_name = "frontend-cdn-${var.site_name}-${var.environment}"
  domain      = var.domain
  tags = {
    Project     = title(var.site_name)
    Managed-by  = "Terragrunt"
    Service     = "website"
    Tier        = "front-end"
    Environment = var.environment
  }
}

## S3 RESOURCES ##
resource "aws_s3_bucket" "bucket" {
  bucket = local.bucket_name
  tags   = local.tags
}
// resource "aws_s3_bucket_acl" "bucket-acl" {
//   bucket = aws_s3_bucket.bucket.id
//   acl    = "private"
// }
resource "aws_s3_bucket_public_access_block" "access_block" {
  bucket                  = aws_s3_bucket.bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_website_configuration" "website_endpoint" {
  bucket = aws_s3_bucket.bucket.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "index.html"
  }
}
# add bucket policy to let the cloudFront origin_access_control get objects
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowCloudFrontServicePrincipal"
      Effect = "Allow"
      Principal = {
        Service = "cloudfront.amazonaws.com"
      }
      Action = [
        "s3:GetObject",
        "s3:ListBucket",
      ]
      Resource = [
        aws_s3_bucket.bucket.arn,
        "${aws_s3_bucket.bucket.arn}/*",
      ]
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = aws_cloudfront_distribution.cloudfront.arn
        }
      }
    }]
  })
}

## CLOUDFRONT RESOURCES ##
# manages an cloudFront origin access control which is used with an S3 bucket as the origin
resource "aws_cloudfront_origin_access_control" "origin_access_control" {
  provider                          = aws.virginia
  name                              = "cdn-${var.site_name}.${var.environment}"
  description                       = "limit S3 bucket access to only authenticated from CloudFront"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
# cloudFront distribution with an S3 origin
resource "aws_cloudfront_distribution" "cloudfront" {
  provider            = aws.virginia
  enabled             = true
  is_ipv6_enabled     = false
  aliases             = var.aws_acm_certificate ? ["${var.cname}.${var.domain}"] : []
  comment             = "${var.cname}.${var.domain}"
  default_root_object = "index.html"
  tags                = local.tags
  lifecycle {
    precondition {
      condition = alltrue([
        for behavior in var.additional_behaviors : contains(var.additional_origins[*].origin_id, behavior.target_origin_id)
      ])
      error_message = "Cada behavior adicional deve referenciar uma origin cadastrada em additional_origins."
    }
    precondition {
      condition     = !contains(var.additional_origins[*].origin_id, local.bucket_name)
      error_message = "O origin_id adicional nao pode ser igual ao nome do bucket S3 do frontend."
    }
  }

  origin {
    domain_name              = aws_s3_bucket.bucket.bucket_regional_domain_name
    origin_id                = aws_s3_bucket.bucket.id
    origin_access_control_id = aws_cloudfront_origin_access_control.origin_access_control.id
  }
  # Custom origins HTTPS adicionais, sem mTLS ou Origin Shield.
  dynamic "origin" {
    for_each = var.additional_origins
    content {
      origin_id           = origin.value.origin_id
      domain_name         = origin.value.domain_name
      origin_path         = origin.value.origin_path
      connection_attempts = origin.value.connection_attempts
      connection_timeout  = origin.value.connection_timeout

      custom_origin_config {
        http_port                = 80
        https_port               = 443
        origin_protocol_policy   = "https-only"
        origin_ssl_protocols     = ["TLSv1.2"]
        origin_read_timeout      = origin.value.origin_read_timeout
        origin_keepalive_timeout = origin.value.origin_keepalive_timeout
        ip_address_type          = "ipv4"
      }
    }
  }

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = aws_s3_bucket.bucket.id
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = data.aws_cloudfront_cache_policy.cache.id
    #origin_request_policy_id = data.aws_cloudfront_origin_request_policy.origin_request.id # headers and cookies requests that CloudFront sends to your origin
    compress = true
  }
  # A ordem da lista define a prioridade das rotas adicionais.
  dynamic "ordered_cache_behavior" {
    for_each = var.additional_behaviors
    iterator = behavior
    content {
      path_pattern             = behavior.value.path_pattern
      target_origin_id         = behavior.value.target_origin_id
      allowed_methods          = behavior.value.allowed_methods
      cached_methods           = behavior.value.cached_methods
      viewer_protocol_policy   = "redirect-to-https"
      cache_policy_id          = data.aws_cloudfront_cache_policy.additional[behavior.value.cache_policy_name].id
      origin_request_policy_id = data.aws_cloudfront_origin_request_policy.additional[behavior.value.origin_request_policy_name].id
      compress                 = true
    }
  }

  # HTML do frontend tem prioridade depois das rotas adicionais.
  ordered_cache_behavior {
    path_pattern               = "*.html"
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD", "OPTIONS"]
    target_origin_id           = aws_s3_bucket.bucket.id
    cache_policy_id            = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" #Managed-CachingDisabled
    response_headers_policy_id = aws_cloudfront_response_headers_policy.policy.id
    compress                   = true
    viewer_protocol_policy     = "redirect-to-https"
  }
  # Fallback global existente: tambem converte respostas 404 das APIs em HTML/200.
  custom_error_response {
    error_code            = 404
    error_caching_min_ttl = 10
    response_page_path    = "/index.html"
    response_code         = 200
  }
  # Restriction type whitelist/blacklist and locations 
  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }
  # appends the arn of an existing ssl certificate or use cloudfront default certificate
  dynamic "viewer_certificate" {
    for_each = var.aws_acm_certificate == true ? [1] : []
    content {
      acm_certificate_arn      = data.aws_acm_certificate.acm_cert[0].arn
      ssl_support_method       = "sni-only"
      minimum_protocol_version = "TLSv1.2_2021"
    }
  }
  dynamic "viewer_certificate" {
    for_each = var.aws_acm_certificate == false ? [1] : []
    content {
      cloudfront_default_certificate = true
    }
  }
  web_acl_id = (var.environment == "prod" && var.enable_waf == true) ? aws_wafv2_web_acl.web_acl[0].arn : null
  # # Enable real-time log configuration
  # logging_config {
  #   include_cookies = false
  #   bucket          = "mylogs.s3.amazonaws.com"
  #   prefix          = "myprefix"
  # }
}
# CloudFront response headers policy no cache for html files
resource "aws_cloudfront_response_headers_policy" "policy" {
  name    = "html-cache-control-${var.site_name}-${var.environment}"
  comment = "disable cache for html files"
  custom_headers_config {
    items {
      header   = "Cache-Control"
      override = false
      value    = "no-cache, no-store, max-age=0, must-revalidate"
    }
  }
}

### WAF WEB ACL ###
resource "aws_wafv2_web_acl" "web_acl" {
  count       = (var.environment == "prod" && var.enable_waf == true) ? 1 : 0
  provider    = aws.virginia
  name        = "CreatedByCloudFront-${var.site_name}"
  description = "Managed-by terraform"
  scope       = "CLOUDFRONT"
  default_action {
    allow {}
  }
  rule {
    name     = "AWS-AWSManagedRulesAmazonIpReputationList"
    priority = 0
    override_action {
      count {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesAmazonIpReputationList"
    }
  }
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1
    override_action {
      count {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesCommonRuleSet"
    }
  }
  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2
    override_action {
      count {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    }
  }
  rule {
    name     = "AWS-AWSManagedRulesBotControlRuleSet"
    priority = 3
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesBotControlRuleSet"

        managed_rule_group_configs {
          aws_managed_rules_bot_control_rule_set {
            inspection_level = "COMMON"
          }
        }

        rule_action_override {
          name = "CategoryAdvertising"
          action_to_use {
            count {}
          }
        }

        rule_action_override {
          name = "CategoryArchiver"
          action_to_use {
            count {}
          }
        }

        rule_action_override {
          name = "CategoryContentFetcher"
          action_to_use {
            count {}
          }
        }

        rule_action_override {
          name = "CategoryEmailClient"
          action_to_use {
            count {}
          }
        }

        rule_action_override {
          name = "CategoryHttpLibrary"
          action_to_use {
            count {}
          }
        }

        rule_action_override {
          name = "CategoryLinkChecker"
          action_to_use {
            count {}
          }
        }

        rule_action_override {
          name = "CategoryMiscellaneous"
          action_to_use {
            count {}
          }
        }

        rule_action_override {
          name = "CategoryMonitoring"
          action_to_use {
            count {}
          }
        }

        rule_action_override {
          name = "CategoryScrapingFramework"
          action_to_use {
            count {}
          }
        }

        rule_action_override {
          name = "CategorySearchEngine"
          action_to_use {
            count {}
          }
        }

        rule_action_override {
          name = "CategorySecurity"
          action_to_use {
            count {}
          }
        }

        rule_action_override {
          name = "CategorySeo"
          action_to_use {
            count {}
          }
        }

        rule_action_override {
          name = "CategorySocialMedia"
          action_to_use {
            count {}
          }
        }

        rule_action_override {
          name = "CategoryAI"
          action_to_use {
            count {}
          }
        }

        rule_action_override {
          name = "SignalAutomatedBrowser"
          action_to_use {
            count {}
          }
        }

        rule_action_override {
          name = "SignalKnownBotDataCenter"
          action_to_use {
            count {}
          }
        }

        rule_action_override {
          name = "SignalNonBrowserUserAgent"
          action_to_use {
            count {}
          }
        }
      }
    }
    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesBotControlRuleSet"
    }
  }
  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "friendly-metric-name"
    sampled_requests_enabled   = false
  }
}

