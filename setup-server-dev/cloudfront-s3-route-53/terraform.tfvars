################################################################################
# General Configuration
################################################################################

aws_region   = "us-east-1"
aws_profile  = "kaopiz-dev" # Change to your AWS profile: kaopiz-dev, default, etc.
environment  = "dev"
project_name = "dfkms"

default_tags = {

}

################################################################################
# S3 Bucket Configuration
################################################################################

s3_bucket_name         = "dfkms-fe-dev-1"
s3_force_destroy       = false
s3_versioning_enabled  = false
s3_block_public_access = true

# Server-side encryption (default: AES256)
s3_server_side_encryption = {
  sse_algorithm      = "AES256"
  kms_master_key_id  = null
  bucket_key_enabled = true
}

# Lifecycle rules (optional)
# s3_lifecycle_rules = [
#   {
#     id     = "cleanup-old-versions"
#     status = "Enabled"

#     noncurrent_version_transition = [
#       {
#         days          = 30
#         storage_class = "STANDARD_IA"
#       },
#       {
#         days          = 90
#         storage_class = "GLACIER"
#       }
#     ]

#     noncurrent_version_expiration = {
#       days = 365
#     }
#   }
# ]

# CORS rules (optional - uncomment if needed)
# s3_cors_rules = [
#   {
#     allowed_headers = ["*"]
#     allowed_methods = ["GET", "HEAD"]
#     allowed_origins = ["https://example.com"]
#     expose_headers  = ["ETag"]
#     max_age_seconds = 3600
#   }
# ]

################################################################################
# CloudFront Configuration
################################################################################

cloudfront_enabled             = true
cloudfront_default_root_object = "index.html"
cloudfront_price_class         = "PriceClass_100" # Use PriceClass_All for global distribution
cloudfront_http_version        = "http2and3"
cloudfront_ipv6_enabled        = true
cloudfront_comment             = "Production website distribution"

# TLS configuration
cloudfront_minimum_protocol_version = "TLSv1.2_2021"

# Cache TTL settings
cloudfront_min_ttl     = 0
cloudfront_default_ttl = 3600  # 1 hour
cloudfront_max_ttl     = 86400 # 24 hours

# Geo restriction (optional)
cloudfront_geo_restriction_type      = "none"
cloudfront_geo_restriction_locations = []

# Custom error responses for SPA (React, Vue, Angular, etc.)
cloudfront_custom_error_responses = [
  {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  },
  {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  },
  {
    error_code            = 500
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }
]

# CloudFront access logging (optional)
cloudfront_logging_enabled = false
cloudfront_logging_bucket  = "" # e.g., "my-logs-bucket.s3.amazonaws.com"
cloudfront_logging_prefix  = "cloudfront-logs/"

# WAF (optional)
cloudfront_waf_web_acl_id = null

################################################################################
# Domain / Route53 Configuration
################################################################################

create_route53_records    = false
domain_name               = "dfkms-dev.dev.kaopiz.com"
subject_alternative_names = []
route53_zone_id           = "Z0030414BPCHYIP57A60"
route53_zone_name         = "dev.kaopiz.com"

################################################################################
# ACM Certificate Configuration
################################################################################

create_certificate              = false
wait_for_certificate_validation = true
existing_certificate_arn        = null # Use if create_certificate = false
