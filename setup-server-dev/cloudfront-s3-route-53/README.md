# CloudFront + S3 + Route53 Terraform Module

Terraform configuration để deploy static website sử dụng S3, CloudFront với custom domain thông qua Route53.

## 🏗️ Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│     Route53     │────▶│    CloudFront    │────▶│    S3 Bucket    │
│   DNS Records   │     │   Distribution   │     │  Static Files   │
│   (A/AAAA)      │     │   (with OAC)     │     │                 │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                               │
                               │
                        ┌──────┴──────┐
                        │     ACM     │
                        │ Certificate │
                        │ (us-east-1) │
                        └─────────────┘
```

## ✨ Features

- **S3 Bucket**: Private bucket với server-side encryption, versioning, và lifecycle rules
- **CloudFront Distribution**: CDN với Origin Access Control (OAC) - phương pháp mới thay thế OAI
- **ACM Certificate**: SSL/TLS certificate tự động validation qua DNS
- **Route53 Records**: A và AAAA records alias tới CloudFront
- **Security Best Practices**:
  - Block all public access to S3
  - Deny insecure transport (HTTP only over HTTPS)
  - TLS 1.2 minimum
  - Origin Access Control for S3 access

## 📁 File Structure

```
cloudfront-s3-route-53/
├── main.tf                    # Main configuration
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── versions.tf                # Provider requirements
├── terraform.tfvars.example   # Example configuration
└── README.md                  # This file
```

## 🚀 Quick Start

### 1. Prerequisites

- Terraform >= 1.5.7
- AWS CLI configured with appropriate credentials
- Route53 hosted zone already created for your domain

### 2. Configuration

Copy và chỉnh sửa file tfvars:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Cập nhật các giá trị quan trọng trong `terraform.tfvars`:

```hcl
# Required
project_name    = "my-website"
s3_bucket_name  = "my-unique-bucket-name"
domain_name     = "example.com"
route53_zone_id = "Z1234567890ABCDEFGHIJ"  # Lấy từ Route53 console

# Optional
subject_alternative_names = ["www.example.com"]
environment               = "production"
```

### 3. Deploy

```bash
# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Apply changes
terraform apply
```

### 4. Upload Content

Sau khi deploy, upload static files lên S3:

```bash
# Sync local files to S3
aws s3 sync ./dist s3://your-bucket-name --delete

# Invalidate CloudFront cache
aws cloudfront create-invalidation --distribution-id XXXXXXXXX --paths "/*"
```

## 📖 Variables Reference

### General

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `aws_region` | AWS region for resources | `string` | `"ap-southeast-1"` |
| `environment` | Environment name | `string` | `"dev"` |
| `project_name` | Project name for resource naming | `string` | - |
| `default_tags` | Default tags for all resources | `map(string)` | `{}` |

### S3

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `s3_bucket_name` | S3 bucket name | `string` | - |
| `s3_force_destroy` | Force destroy bucket with contents | `bool` | `false` |
| `s3_versioning_enabled` | Enable versioning | `bool` | `true` |
| `s3_server_side_encryption` | SSE configuration | `object` | AES256 |
| `s3_lifecycle_rules` | Lifecycle rules | `any` | `[]` |

### CloudFront

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `cloudfront_enabled` | Enable distribution | `bool` | `true` |
| `cloudfront_default_root_object` | Default root object | `string` | `"index.html"` |
| `cloudfront_price_class` | Price class | `string` | `"PriceClass_100"` |
| `cloudfront_minimum_protocol_version` | Min TLS version | `string` | `"TLSv1.2_2021"` |
| `cloudfront_custom_error_responses` | Custom error responses for SPA | `list` | `[]` |

### Domain

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `domain_name` | Primary domain name | `string` | - |
| `subject_alternative_names` | Additional domain names | `list(string)` | `[]` |
| `route53_zone_id` | Route53 hosted zone ID | `string` | - |

## 📤 Outputs

| Output | Description |
|--------|-------------|
| `s3_bucket_id` | S3 bucket name |
| `s3_bucket_arn` | S3 bucket ARN |
| `cloudfront_distribution_id` | CloudFront distribution ID |
| `cloudfront_distribution_domain_name` | CloudFront domain name |
| `acm_certificate_arn` | ACM certificate ARN |
| `website_url` | Primary website URL |
| `cloudfront_invalidation_command` | CLI command to invalidate cache |
| `s3_sync_command` | CLI command to sync files |

## 🔧 Common Use Cases

### Single Page Application (SPA)

Cho React, Vue, Angular apps, thêm custom error responses:

```hcl
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
  }
]
```

### Multiple Domains

Hỗ trợ root domain và www:

```hcl
domain_name               = "example.com"
subject_alternative_names = ["www.example.com"]
```

### Using Existing Certificate

Nếu đã có ACM certificate:

```hcl
create_certificate       = false
existing_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/xxx"
```

## ⚠️ Important Notes

1. **ACM Certificate Region**: Certificate cho CloudFront **phải** ở region `us-east-1`. Module tự động tạo ở đúng region.

2. **DNS Propagation**: Sau khi apply lần đầu, DNS có thể mất 5-10 phút để propagate.

3. **S3 Bucket Names**: Phải globally unique.

4. **Route53 Zone**: Hosted zone phải tồn tại trước khi chạy Terraform.

## 🔐 Security

Module này implement các security best practices:

- S3 bucket blocks all public access
- CloudFront uses Origin Access Control (OAC)
- Enforces HTTPS-only (redirects HTTP to HTTPS)
- TLS 1.2 minimum protocol version
- Deny insecure transport policy on S3
- Server-side encryption enabled

## 📝 License

MIT License
