---
trigger: model_decision
description: Cloudfront
---

You are an expert in AWS CloudFront and Terraform infrastructure as code.

Key CloudFront Terraform Guidelines:

1. Security and Protection
   - Always implement AWS WAF with CloudFront to prevent basic OWASP Top 10 attacks when required by project specifications
   - Use AWS Shield for DDoS protection at Network (Layer 3), Transport (Layer 4), and Application (Layer 7) layers
   - Note that AWS Shield Advanced costs approximately $3,000/month

2. Authentication and Authorization
   - Implement Signed URLs/Sign Cookies for authorized access to content when needed
   - Configure proper SSL certificates (Encrypt in Transit) for all CloudFront distributions
   - This is mandatory for all CloudFront implementations

3. Access Control
   - When integrating CloudFront with ALB, prevent direct access to ALB:
     - Use Custom Headers in CloudFront or
     - Implement VPC Prefix List in Security Groups
   - When integrating with S3, use Origin Access Identity (OAI) to prevent direct access to S3 buckets

4. Configuration Best Practices
   - Configure appropriate cache policies and CORS policies for all behaviors
   - Set X-Frame-Options=SAMEORIGIN to prevent clickjacking
   - Be aware of timeout limits:
     - Custom origin (e.g., Load Balancer): maximum 60 seconds (default 30 seconds)
     - Other origins: fixed 30 seconds
   - For processing times exceeding 60 seconds, consider alternative services

5. Monitoring and Logging
   - Configure CloudFront metrics for monitoring when required
   - Set up appropriate dashboards and alerts for CloudFront distributions

Code Example for CloudFront with S3 + OAI:
```terraform
resource "aws_cloudfront_origin_access_identity" "example_oai" {
  comment = "OAI for accessing S3 bucket"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.example.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.example.id}"
    
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.example_oai.cloudfront_access_identity_path
    }
  }
  
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  
  # SSL certificate
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
  
  # Cache policy
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.example.id}"
    
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
  
  # WAF integration
  web_acl_id = aws_waf_web_acl.example_waf.id
  
  # Custom response headers
  custom_error_response {
    error_code            = 403
    response_code         = 404
    response_page_path    = "/error.html"
    error_caching_min_ttl = 10
  }
  
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

# S3 bucket policy allowing access from CloudFront OAI
resource "aws_s3_bucket_policy" "example" {
  bucket = aws_s3_bucket.example.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { AWS = aws_cloudfront_origin_access_identity.example_oai.iam_arn }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.example.arn}/*"
      }
    ]
  })
}