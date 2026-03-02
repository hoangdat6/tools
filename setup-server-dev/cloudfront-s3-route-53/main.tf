################################################################################
# Local Variables
################################################################################

locals {
  s3_origin_id = "${var.project_name}-s3-origin"

  # Certificate ARN - use existing or newly created
  certificate_arn = var.create_certificate ? module.acm[0].acm_certificate_arn : var.existing_certificate_arn

  # Determine if using custom domain (has certificate)
  use_custom_domain = local.certificate_arn != null

  # All domain names for CloudFront aliases (only when using custom domain)
  cloudfront_aliases = local.use_custom_domain ? concat([var.domain_name], var.subject_alternative_names) : []

  # Common tags
  common_tags = merge(var.default_tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

################################################################################
# S3 Bucket for Static Website
################################################################################

module "s3_bucket" {
  source = "../aws-modules/terraform-aws-s3-bucket"

  bucket        = var.s3_bucket_name
  force_destroy = var.s3_force_destroy

  # Block all public access - CloudFront OAC will access the bucket
  block_public_acls       = var.s3_block_public_access
  block_public_policy     = var.s3_block_public_access
  ignore_public_acls      = var.s3_block_public_access
  restrict_public_buckets = var.s3_block_public_access

  # Object ownership
  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"

  # Versioning
  versioning = var.s3_versioning_enabled ? {
    enabled = true
  } : {}

  # Server-side encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm     = var.s3_server_side_encryption.sse_algorithm
        kms_master_key_id = var.s3_server_side_encryption.kms_master_key_id
      }
      bucket_key_enabled = var.s3_server_side_encryption.bucket_key_enabled
    }
  }

  # Lifecycle rules
  lifecycle_rule = var.s3_lifecycle_rules

  # CORS configuration
  cors_rule = var.s3_cors_rules

  # Attach CloudFront OAC policy
  attach_policy = true
  policy        = data.aws_iam_policy_document.s3_bucket_policy.json

  # Deny insecure transport (HTTP)
  attach_deny_insecure_transport_policy = true

  tags = local.common_tags
}

################################################################################
# S3 Bucket Policy for CloudFront OAC
################################################################################

data "aws_iam_policy_document" "s3_bucket_policy" {
  # Allow CloudFront OAC to access S3
  statement {
    sid    = "AllowCloudFrontOACAccess"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = ["s3:GetObject"]

    resources = ["arn:aws:s3:::${var.s3_bucket_name}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [module.cloudfront.cloudfront_distribution_arn]
    }
  }
}

################################################################################
# ACM Certificate (must be in us-east-1 for CloudFront)
################################################################################

module "acm" {
  source = "../aws-modules/terraform-aws-acm"
  count  = var.create_certificate ? 1 : 0

  providers = {
    aws = aws.us_east_1
  }

  domain_name               = var.domain_name
  zone_id                   = var.route53_zone_id
  subject_alternative_names = var.subject_alternative_names

  validation_method   = "DNS"
  wait_for_validation = var.wait_for_certificate_validation

  tags = local.common_tags
}

################################################################################
# CloudFront Distribution (using module)
################################################################################

module "cloudfront" {
  source = "../aws-modules/terraform-aws-cloudfront"

  # Aliases only when using custom domain
  aliases = length(local.cloudfront_aliases) > 0 ? local.cloudfront_aliases : null

  comment         = var.cloudfront_comment != "" ? var.cloudfront_comment : "${var.project_name} - ${var.environment}"
  enabled         = var.cloudfront_enabled
  http_version    = var.cloudfront_http_version
  is_ipv6_enabled = var.cloudfront_ipv6_enabled
  price_class     = var.cloudfront_price_class

  default_root_object = var.cloudfront_default_root_object

  # Origin Access Control (module handles creation)
  origin_access_control = {
    s3 = {
      description      = "Origin Access Control for ${var.project_name} S3 bucket"
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
  }

  # S3 Origin
  origin = {
    s3 = {
      domain_name               = module.s3_bucket.s3_bucket_bucket_regional_domain_name
      origin_access_control_key = "s3"
    }
  }

  # Default cache behavior
  default_cache_behavior = {
    target_origin_id       = "s3"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    min_ttl     = var.cloudfront_min_ttl
    default_ttl = var.cloudfront_default_ttl
    max_ttl     = var.cloudfront_max_ttl
  }

  # Viewer certificate - conditional based on custom domain usage
  viewer_certificate = local.use_custom_domain ? {
    acm_certificate_arn      = local.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = var.cloudfront_minimum_protocol_version
    } : {
    cloudfront_default_certificate = true
  }

  # Custom error responses (for SPA routing)
  custom_error_response = length(var.cloudfront_custom_error_responses) > 0 ? var.cloudfront_custom_error_responses : null

  # Geo restriction
  restrictions = {
    geo_restriction = {
      restriction_type = var.cloudfront_geo_restriction_type
      locations        = var.cloudfront_geo_restriction_locations
    }
  }

  # Logging (optional)
  logging_config = var.cloudfront_logging_enabled ? {
    bucket          = var.cloudfront_logging_bucket
    include_cookies = false
    prefix          = var.cloudfront_logging_prefix
  } : null

  # WAF (optional)
  web_acl_id = var.cloudfront_waf_web_acl_id

  tags = local.common_tags

  depends_on = [module.acm]
}

################################################################################
# Route53 Records for CloudFront (only when using custom domain)
################################################################################

module "route53_records" {
  source = "../aws-modules/terraform-aws-route53"

  create      = var.create_route53_records && local.use_custom_domain
  create_zone = false
  name        = var.route53_zone_name # Zone name for lookup (e.g., dathv.aws.codestar.vn)

  records = {
    # A record for root domain (IPv4)
    cloudfront_a = {
      name      = var.domain_name
      full_name = var.domain_name
      type      = "A"
      alias = {
        name                   = module.cloudfront.cloudfront_distribution_domain_name
        zone_id                = module.cloudfront.cloudfront_distribution_hosted_zone_id
        evaluate_target_health = false
      }
    }

    # AAAA record for root domain (IPv6)
    cloudfront_aaaa = {
      name      = var.domain_name
      full_name = var.domain_name
      type      = "AAAA"
      alias = {
        name                   = module.cloudfront.cloudfront_distribution_domain_name
        zone_id                = module.cloudfront.cloudfront_distribution_hosted_zone_id
        evaluate_target_health = false
      }
    }
  }

  tags = local.common_tags

  depends_on = [module.cloudfront]
}

# Additional Route53 records for SANs (only when using custom domain)
resource "aws_route53_record" "san_a" {
  for_each = var.create_route53_records && local.use_custom_domain ? toset(var.subject_alternative_names) : toset([])

  zone_id = var.route53_zone_id
  name    = each.value
  type    = "A"

  alias {
    name                   = module.cloudfront.cloudfront_distribution_domain_name
    zone_id                = module.cloudfront.cloudfront_distribution_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "san_aaaa" {
  for_each = var.create_route53_records && local.use_custom_domain ? toset(var.subject_alternative_names) : toset([])

  zone_id = var.route53_zone_id
  name    = each.value
  type    = "AAAA"

  alias {
    name                   = module.cloudfront.cloudfront_distribution_domain_name
    zone_id                = module.cloudfront.cloudfront_distribution_hosted_zone_id
    evaluate_target_health = false
  }
}

