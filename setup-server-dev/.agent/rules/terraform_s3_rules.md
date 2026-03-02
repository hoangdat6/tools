---
trigger: model_decision
description: Rules for AWS S3 services in Terraform with security best practices
---

You are an expert in AWS S3 and Terraform infrastructure as code.

Key S3 Terraform Guidelines:

1. Access Control and Security
   - Always use IAM roles with least privilege when accessing S3 from other AWS services
   - Block public access to S3 buckets by default using the S3 Block Public Access settings
   - Configure restrictive bucket policies that prevent public access
   - Use CloudFront with Origin Access Identity (OAI) for public content delivery
   - Use VPC endpoints for EC2 instances to access S3, especially from private subnets

2. Authentication and Authorization
   - Use pre-signed URLs for temporary, limited access to specific objects
   - For CloudFront distribution of private content, implement Signed URLs/Cookies
   - Implement proper authorization via IAM permissions and resource policies

3. Optimization for Large Files
   - Use pre-signed URLs with multipart upload for large files (>100MB)
   - Configure appropriate timeouts and part sizes for efficient uploads

4. Data Protection
   - Enable versioning to prevent accidental deletion of objects
   - Consider enabling MFA Delete for critical buckets
   - Implement appropriate lifecycle policies to transition objects between storage classes
   - Always enable encryption for sensitive data (SSE-S3 or SSE-KMS)

5. Monitoring and Logging
   - Enable S3 access logging to track bucket access
   - Configure request metrics for monitoring bucket usage
   - Set up CloudWatch alarms and dashboards for S3 monitoring

Code Example for S3 with Best Practices:
```terraform
# S3 bucket with security best practices
resource "aws_s3_bucket" "secure_bucket" {
  bucket = "example-secure-bucket"
  
  tags = {
    Name        = "Secure Bucket"
    Environment = "Production"
  }
}

# Block public access for the bucket
resource "aws_s3_bucket_public_access_block" "secure_bucket_public_access_block" {
  bucket = aws_s3_bucket.secure_bucket.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning
resource "aws_s3_bucket_versioning" "secure_bucket_versioning" {
  bucket = aws_s3_bucket.secure_bucket.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "secure_bucket_encryption" {
  bucket = aws_s3_bucket.secure_bucket.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Enable access logging
resource "aws_s3_bucket" "log_bucket" {
  bucket = "example-log-bucket"
  
  tags = {
    Name        = "S3 Log Bucket"
    Environment = "Production"
  }
}

resource "aws_s3_bucket_logging" "secure_bucket_logging" {
  bucket = aws_s3_bucket.secure_bucket.id
  
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/"
}

# Lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "secure_bucket_lifecycle" {
  bucket = aws_s3_bucket.secure_bucket.id
  
  rule {
    id     = "transition-to-ia-glacier"
    status = "Enabled"
    
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
    
    expiration {
      days = 365
    }
  }
}

# Bucket policy - Allow CloudFront OAI Access
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for S3 bucket access"
}

resource "aws_s3_bucket_policy" "secure_bucket_policy" {
  bucket = aws_s3_bucket.secure_bucket.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "s3:GetObject"
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.secure_bucket.arn}/*"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.oai.iam_arn
        }
      },
      {
        Action   = "s3:*"
        Effect   = "Deny"
        Resource = [
          aws_s3_bucket.secure_bucket.arn,
          "${aws_s3_bucket.secure_bucket.arn}/*"
        ]
        Principal = "*"
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# VPC Endpoint for S3
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.region}.s3"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = ["s3:GetObject", "s3:ListBucket"]
        Effect    = "Allow"
        Resource  = [aws_s3_bucket.secure_bucket.arn, "${aws_s3_bucket.secure_bucket.arn}/*"]
        Principal = "*"
      }
    ]
  })
  
  route_table_ids = [aws_route_table.private.id]
  
  tags = {
    Name = "S3 VPC Endpoint"
  }
}

# CloudWatch Metric Alarm for S3
resource "aws_cloudwatch_metric_alarm" "s3_4xx_errors" {
  alarm_name          = "s3-4xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "4xxErrors"
  namespace           = "AWS/S3"
  period              = "60"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This alarm monitors for S3 4XX errors"
  
  dimensions = {
    BucketName = aws_s3_bucket.secure_bucket.id
  }
  
  alarm_actions = [aws_sns_topic.alerts.arn]
}

# Request metrics configuration
resource "aws_s3_bucket_metric" "secure_bucket_metrics" {
  bucket = aws_s3_bucket.secure_bucket.id
  name   = "EntireBucket"
}