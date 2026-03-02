################################################################################
# Terraform and Provider Configuration
################################################################################

terraform {
  required_version = ">= 1.5.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }

  # Backend configuration - uncomment and configure as needed
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "cloudfront-s3-route53/terraform.tfstate"
  #   region         = "ap-southeast-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

################################################################################
# AWS Provider Configuration
################################################################################

# Default provider for main resources
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = var.default_tags
  }
}

# Provider for ACM certificate (must be us-east-1 for CloudFront)
provider "aws" {
  alias   = "us_east_1"
  region  = "us-east-1"
  profile = var.aws_profile

  default_tags {
    tags = var.default_tags
  }
}
