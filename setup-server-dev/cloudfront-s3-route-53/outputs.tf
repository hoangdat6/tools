################################################################################
# S3 Bucket Outputs
################################################################################

output "s3_bucket_id" {
  description = "The name of the S3 bucket"
  value       = module.s3_bucket.s3_bucket_id
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = module.s3_bucket.s3_bucket_arn
}

output "s3_bucket_regional_domain_name" {
  description = "The regional domain name of the S3 bucket"
  value       = module.s3_bucket.s3_bucket_bucket_regional_domain_name
}

output "s3_bucket_region" {
  description = "The AWS region of the S3 bucket"
  value       = module.s3_bucket.s3_bucket_region
}

################################################################################
# CloudFront Outputs
################################################################################

output "cloudfront_distribution_id" {
  description = "The ID of the CloudFront distribution"
  value       = module.cloudfront.cloudfront_distribution_id
}

output "cloudfront_distribution_arn" {
  description = "The ARN of the CloudFront distribution"
  value       = module.cloudfront.cloudfront_distribution_arn
}

output "cloudfront_distribution_domain_name" {
  description = "The domain name of the CloudFront distribution"
  value       = module.cloudfront.cloudfront_distribution_domain_name
}

output "cloudfront_distribution_hosted_zone_id" {
  description = "The CloudFront Route 53 zone ID"
  value       = module.cloudfront.cloudfront_distribution_hosted_zone_id
}

output "cloudfront_distribution_status" {
  description = "The status of the CloudFront distribution"
  value       = module.cloudfront.cloudfront_distribution_status
}

output "cloudfront_origin_access_controls" {
  description = "The CloudFront Origin Access Controls"
  value       = module.cloudfront.cloudfront_origin_access_controls
}

################################################################################
# ACM Certificate Outputs
################################################################################

output "acm_certificate_arn" {
  description = "The ARN of the ACM certificate"
  value       = var.create_certificate ? module.acm[0].acm_certificate_arn : var.existing_certificate_arn
}

output "acm_certificate_status" {
  description = "The status of the ACM certificate"
  value       = var.create_certificate ? module.acm[0].acm_certificate_status : null
}

output "acm_certificate_domain_validation_options" {
  description = "Domain validation options for ACM certificate"
  value       = var.create_certificate ? module.acm[0].acm_certificate_domain_validation_options : null
}

################################################################################
# Route53 Outputs
################################################################################

output "route53_records" {
  description = "Route53 records created for CloudFront"
  value       = var.create_route53_records ? module.route53_records.records : null
}

################################################################################
# Access URLs
################################################################################

output "website_url" {
  description = "The website URL (primary domain or CloudFront default)"
  value       = local.use_custom_domain ? "https://${var.domain_name}" : "https://${module.cloudfront.cloudfront_distribution_domain_name}"
}

output "website_aliases" {
  description = "All website URLs including aliases (empty if no custom domain)"
  value       = local.use_custom_domain ? [for domain in concat([var.domain_name], var.subject_alternative_names) : "https://${domain}"] : ["https://${module.cloudfront.cloudfront_distribution_domain_name}"]
}

################################################################################
# Useful Commands
################################################################################

output "cloudfront_invalidation_command" {
  description = "AWS CLI command to invalidate CloudFront cache"
  value       = "aws cloudfront create-invalidation --distribution-id ${module.cloudfront.cloudfront_distribution_id} --paths '/*'"
}

output "s3_sync_command" {
  description = "AWS CLI command to sync files to S3 bucket"
  value       = "aws s3 sync ./dist s3://${module.s3_bucket.s3_bucket_id} --delete"
}
