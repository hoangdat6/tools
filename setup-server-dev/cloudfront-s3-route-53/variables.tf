################################################################################
# General Variables
################################################################################

variable "aws_region" {
  description = "AWS region for main resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use for authentication"
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default     = {}
}

################################################################################
# S3 Variables
################################################################################

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for static website hosting"
  type        = string
}

variable "s3_force_destroy" {
  description = "Boolean that indicates all objects should be deleted from the bucket when destroying"
  type        = bool
  default     = false
}

variable "s3_versioning_enabled" {
  description = "Enable versioning for S3 bucket"
  type        = bool
  default     = false
}

variable "s3_block_public_access" {
  description = "Block all public access to S3 bucket"
  type        = bool
  default     = true
}

variable "s3_server_side_encryption" {
  description = "Server-side encryption configuration"
  type = object({
    sse_algorithm      = optional(string, "AES256")
    kms_master_key_id  = optional(string, null)
    bucket_key_enabled = optional(bool, true)
  })
  default = {
    sse_algorithm      = "AES256"
    kms_master_key_id  = null
    bucket_key_enabled = true
  }
}

variable "s3_lifecycle_rules" {
  description = "S3 bucket lifecycle rules"
  type        = any
  default     = []
}

variable "s3_cors_rules" {
  description = "CORS rules for S3 bucket"
  type        = any
  default     = []
}

################################################################################
# CloudFront Variables
################################################################################

variable "cloudfront_enabled" {
  description = "Enable CloudFront distribution"
  type        = bool
  default     = true
}

variable "cloudfront_default_root_object" {
  description = "Default root object for CloudFront"
  type        = string
  default     = "index.html"
}

variable "cloudfront_price_class" {
  description = "CloudFront price class (PriceClass_All, PriceClass_200, PriceClass_100)"
  type        = string
  default     = "PriceClass_100"
}

variable "cloudfront_minimum_protocol_version" {
  description = "Minimum TLS version for CloudFront"
  type        = string
  default     = "TLSv1.2_2021"
}

variable "cloudfront_http_version" {
  description = "HTTP version for CloudFront"
  type        = string
  default     = "http2and3"
}

variable "cloudfront_ipv6_enabled" {
  description = "Enable IPv6 for CloudFront"
  type        = bool
  default     = true
}

variable "cloudfront_comment" {
  description = "Comment for CloudFront distribution"
  type        = string
  default     = ""
}

variable "cloudfront_geo_restriction_type" {
  description = "CloudFront geo restriction type (none, whitelist, blacklist)"
  type        = string
  default     = "none"
}

variable "cloudfront_geo_restriction_locations" {
  description = "List of country codes for geo restriction"
  type        = list(string)
  default     = []
}

variable "cloudfront_default_ttl" {
  description = "Default TTL for CloudFront cache"
  type        = number
  default     = 3600
}

variable "cloudfront_min_ttl" {
  description = "Minimum TTL for CloudFront cache"
  type        = number
  default     = 0
}

variable "cloudfront_max_ttl" {
  description = "Maximum TTL for CloudFront cache"
  type        = number
  default     = 86400
}

variable "cloudfront_custom_error_responses" {
  description = "Custom error responses for CloudFront (e.g., for SPA routing)"
  type = list(object({
    error_code            = number
    response_code         = optional(number)
    response_page_path    = optional(string)
    error_caching_min_ttl = optional(number)
  }))
  default = []
}

variable "cloudfront_logging_enabled" {
  description = "Enable CloudFront access logging"
  type        = bool
  default     = false
}

variable "cloudfront_logging_bucket" {
  description = "S3 bucket for CloudFront access logs (domain name format: bucket-name.s3.amazonaws.com)"
  type        = string
  default     = ""
}

variable "cloudfront_logging_prefix" {
  description = "Prefix for CloudFront access logs"
  type        = string
  default     = "cloudfront-logs/"
}

variable "cloudfront_waf_web_acl_id" {
  description = "WAF Web ACL ID to associate with CloudFront"
  type        = string
  default     = null
}

################################################################################
# Route53 / Domain Variables
################################################################################

variable "domain_name" {
  description = "Primary domain name for CloudFront distribution"
  type        = string
}

variable "subject_alternative_names" {
  description = "Additional domain names (SANs) for SSL certificate"
  type        = list(string)
  default     = []
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID for the domain"
  type        = string
}

variable "route53_zone_name" {
  description = "Route53 hosted zone name (e.g., example.com)"
  type        = string
}

variable "create_route53_records" {
  description = "Create Route53 DNS records for CloudFront"
  type        = bool
  default     = true
}

variable "wait_for_certificate_validation" {
  description = "Wait for ACM certificate validation to complete"
  type        = bool
  default     = true
}

################################################################################
# ACM Variables
################################################################################

variable "create_certificate" {
  description = "Create ACM certificate for CloudFront"
  type        = bool
  default     = true
}

variable "existing_certificate_arn" {
  description = "ARN of existing ACM certificate (if not creating new one)"
  type        = string
  default     = null
}
