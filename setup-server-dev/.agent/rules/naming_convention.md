# AWS Infrastructure Naming Convention

## Overview

This document defines the standardized naming convention for all AWS resources across infrastructure patterns (P01, P02, etc.) to ensure consistency, clarity, and maintainability.

**Project Name**: `patterns` (for this repository)

## Core Naming Format

```
<project>-<environment>-<resource-type>-<component>-<identifier>
```

**Examples:** 
- `patterns-dev-vpc-public-subnet-a`
- `patterns-prod-rds-snapshot-final`
- `webapp-staging-alb`

### Components Breakdown

- **`<project>`** *(required)*: Project identifier for clear resource ownership (e.g., `patterns`, `webapp`, `api`, `mobile`)
- **`<environment>`**: Environment identifier (e.g., `dev`, `staging`, `prod`)
- **`<resource-type>`**: Primary resource category (e.g., `vpc`, `rds`, `alb`, `ec2`)
- **`<component>`**: Specific component or tier (e.g., `public`, `private`, `database`, `subnet`, `rt`)
- **`<identifier>`**: Unique identifier when multiple instances exist (e.g., AZ suffix, instance number)

### Why Always Include Project Name?

1. **Clear Ownership**: Easy to identify which project owns the resource
2. **Multi-Account Safety**: Prevents naming conflicts if resources are migrated or consolidated
3. **Cost Tracking**: Simplifies cost allocation and billing reports
4. **Consistency**: Single naming standard across all deployments
5. **Scalability**: No need to rename resources when project grows
6. **Search & Filter**: Easy to find all resources for a specific project in AWS Console

### Naming Rules

1. **Always include project name** - First component of every resource name
2. **Use lowercase with hyphens** as separators (kebab-case)
3. **Be descriptive but concise** - avoid overly long names
4. **Include environment** after project name (e.g., `patterns-dev`, `webapp-prod`)
5. **Use consistent abbreviations**:
   - `rt` = Route Table
   - `sg` = Security Group
   - `gw` = Gateway
   - `asg` = Auto Scaling Group
   - `lt` = Launch Template
   - `tg` = Target Group
   - `db` = Database
6. **Availability Zone suffixes**: Use short form (e.g., `-a`, `-b`) instead of full AZ name
7. **Omit redundant words**: If resource type is clear from context
8. **Keep project names short**: 3-8 characters ideal (e.g., `patterns`, `webapp`, `api`)

### Project Name Guidelines

- **For this repository**: Use `patterns` as project name
- **For your applications**: Use application/product name (e.g., `webapp`, `api`, `mobile`)
- **Avoid generic names**: Don't use `app`, `project`, `system`
- **Be consistent**: Same project name across all environments

## Resource-Specific Naming Conventions

### 1. VPC Module (`modules/vpc/`)

#### VPC Core
```hcl
# VPC
Name: <project>-<env>-vpc
Example: 
  - patterns-dev-vpc
  - webapp-prod-vpc
  - api-staging-vpc

# Internet Gateway
Name: <project>-<env>-vpc-igw
Example: 
  - patterns-dev-vpc-igw
  - webapp-prod-vpc-igw
```

#### Subnets
```hcl
# Public Subnets (for ALB, NAT Gateway)
Name: <project>-<env>-vpc-public-subnet-<az>
Example: 
  - patterns-dev-vpc-public-subnet-a
  - webapp-prod-vpc-public-subnet-a

# Private Subnets (for EC2 instances)
Name: <project>-<env>-vpc-private-subnet-<az>
Example: 
  - patterns-dev-vpc-private-subnet-a
  - api-staging-vpc-private-subnet-b

# Database Subnets (for RDS)
Name: <project>-<env>-vpc-database-subnet-<az>
Example: 
  - patterns-dev-vpc-database-subnet-a
  - mobile-prod-vpc-database-subnet-b
```

#### Route Tables
```hcl
# Public Route Table
Name: <project>-<env>-vpc-public-rt
Example: 
  - patterns-dev-vpc-public-rt
  - webapp-prod-vpc-public-rt

# Private Route Table (per AZ if multiple NAT Gateways)
Name: <project>-<env>-vpc-private-rt[-<az>]
Example: 
  - patterns-dev-vpc-private-rt (single NAT)
  - patterns-dev-vpc-private-rt-a (multi-AZ NAT)
  - api-prod-vpc-private-rt-b

# Database Route Table
Name: <project>-<env>-vpc-database-rt
Example: 
  - patterns-dev-vpc-database-rt
  - mobile-prod-vpc-database-rt
```

#### NAT & Elastic IP
```hcl
# NAT Gateway
Name: <project>-<env>-vpc-nat-gw-<az>
Example: 
  - patterns-dev-vpc-nat-gw-a
  - webapp-prod-vpc-nat-gw-a

# Elastic IP for NAT
Name: <project>-<env>-vpc-eip-nat-<az>
Example: 
  - patterns-dev-vpc-eip-nat-a
  - api-staging-vpc-eip-nat-b
```

### 2. Security Groups (`modules/security-group/`)

```hcl
# Format
Name: <project>-<env>-<service>-sg
Example:
  - patterns-dev-alb-sg
  - webapp-dev-alb-sg
  - patterns-dev-ec2-sg
  - patterns-dev-rds-sg
  - webapp-prod-bastion-sg
  - api-prod-lambda-sg
```

### 3. RDS Module (`modules/rds/`)

```hcl
# DB Instance
Name: <project>-<env>-db[-<purpose>]
Example: 
  - patterns-dev-db
  - webapp-prod-db
  - api-dev-db-analytics

# DB Subnet Group
Name: <project>-<env>-db-subnet-group
Example: 
  - patterns-dev-db-subnet-group
  - mobile-prod-db-subnet-group

# DB Parameter Group
Name: <project>-<env>-db-params[-<engine>]
Example: 
  - patterns-dev-db-params
  - patterns-dev-db-params-mysql84
  - webapp-prod-db-params-postgres15

# Final Snapshot
Name: <project>-<env>-db-snapshot-final[-<timestamp>]
Example: 
  - patterns-dev-db-snapshot-final-20260109
  - api-prod-db-snapshot-final-20260109

# Read Replica (if applicable)
Name: <project>-<env>-db-replica[-<number>]
Example: 
  - patterns-prod-db-replica-1
  - webapp-prod-db-replica-2
```

### 4. ALB Module (`modules/alb/`)

```hcl
# Application Load Balancer
Name: <project>-<env>-alb
Example: patterns-dev-alb, webapp-prod-alb

# Target Group
Name: <project>-<env>-tg[-<protocol>][-<purpose>]
Example:
  - patterns-dev-tg
  - patterns-dev-tg-http
  - webapp-prod-tg-https
  - api-dev-tg-api

# ALB Security Group (auto-generated by module)
Name: <project>-<env>-alb-sg
Example: patterns-dev-alb-sg
```

### 5. EC2 / Auto Scaling (`modules/asg/`, `modules/ec2/`)

```hcl
# Launch Template
Name: <project>-<env>-lt[-<app-name>]
Example:
  - patterns-dev-lt
  - webapp-prod-lt-webapp
  - api-dev-lt-api

# Auto Scaling Group
Name: <project>-<env>-asg[-<app-name>]
Example:
  - patterns-dev-asg
  - webapp-prod-asg-frontend

# EC2 Instances (named by ASG or manually)
Name: <project>-<env>-instance[-<purpose>]
Example:
  - patterns-dev-instance (ASG auto-tagged)
  - webapp-prod-bastion
```

### 6. IAM Module (`modules/iam/`)

```hcl
# IAM Role
Name: <project>-<env>-<service>-role[-<purpose>]
Example:
  - patterns-dev-ec2-role
  - webapp-prod-lambda-role
  - patterns-dev-rds-monitoring-role

# IAM Policy (custom)
Name: <project>-<env>-<service>-policy[-<purpose>]
Example:
  - patterns-dev-ec2-policy
  - webapp-prod-s3-access-policy

# Instance Profile
Name: <project>-<env>-<service>-instance-profile
Example: patterns-dev-ec2-instance-profile
```

### 7. S3 Module (`modules/s3/`)

```hcl
# S3 Bucket (must be globally unique)
Name: <project>-<env>-<purpose>[-<region>]
Example:
  - patterns-dev-logs-apse1
  - webapp-prod-assets
  - terraform-state-patterns-prod

# Note: Include region suffix if multi-region deployment
```

### 8. CloudWatch (`modules/cloudwatch/`)

```hcl
# Log Group
Name: /aws/<service>/<project>/<env>/<app-name>
Example:
  - /aws/ec2/patterns/dev/webapp
  - /aws/rds/patterns/prod/mysql

# CloudWatch Alarm
Name: <project>-<env>-<resource>-<metric>-alarm
Example:
  - patterns-dev-rds-cpu-alarm
  - webapp-prod-alb-target-unhealthy-alarm
```

### 9. SNS Topics (`modules/sns/`)

```hcl
# SNS Topic
Name: <project>-<env>-<purpose>-topic
Example:
  - patterns-dev-alarms-topic
  - webapp-prod-notifications-topic
```

### 10. Route53 (`modules/route53/`)

```hcl
# Hosted Zone (use actual domain)
Name: <domain.com>
Example: example.com, dev.example.com

# DNS Records (descriptive)
Name: <subdomain>.<domain>
Example:
  - api.dev.example.com
  - www.example.com
```

## Implementation Checklist

### Phase 1: Foundation (VPC Module)
- [x] Route Tables (public/private/database-rt)
- [ ] Subnets (public/private/database-subnet-{az})
- [ ] NAT Gateway (nat-gw-{az})
- [ ] Elastic IP (eip-nat-{az})
- [ ] Internet Gateway (igw)

### Phase 2: Security
- [ ] Security Groups (already consistent)

### Phase 3: Compute
- [ ] Launch Template naming
- [ ] Auto Scaling Group naming
- [ ] EC2 instance naming

### Phase 4: Database
- [ ] RDS instance naming
- [ ] Subnet group naming
- [ ] Parameter group naming
- [ ] Snapshot naming

### Phase 5: Load Balancing
- [ ] ALB naming
- [ ] Target Group naming
- [ ] Listener rules naming

### Phase 6: IAM
- [ ] IAM Role naming (mostly done)
- [ ] IAM Policy naming
- [ ] Instance Profile naming

### Phase 7: Storage & Logging
- [ ] S3 bucket naming
- [ ] CloudWatch log group naming
- [ ] CloudWatch alarm naming

### Phase 8: Patterns
- [ ] Update P01 pattern
- [ ] Update P02-simple pattern
- [ ] Update P02-ha pattern (if exists)

## Migration Strategy

### For Existing Resources

**Option 1: Terraform State Rename (No AWS Changes)**
```bash
terraform state mv 'aws_route_table.public[0]' 'aws_route_table.public[0]'
# Then update tags in terraform code
terraform apply  # Only updates tags
```

**Option 2: Recreate with New Names**
```bash
# WARNING: May cause downtime for some resources
terraform apply  # Creates new resources with new names
# Migrate traffic/data
# Delete old resources
```

**Option 3: Manual Tag Update (Quick Fix)**
```bash
aws ec2 create-tags --resources <resource-id> --tags Key=Name,Value=<new-name>
```

### Testing New Names
1. Apply to `dev` environment first
2. Verify all resources created with correct names
3. Check AWS Console for tag visibility
4. Validate no broken dependencies
5. Apply to `staging` → `prod`

## Common Pitfalls to Avoid

### ❌ Anti-Patterns
```hcl
# Missing project name
Name: dev-vpc-private-subnet-a  # ❌ (which project?)

# Too long and redundant
Name: patterns-dev-vpc-private-subnet-ap-southeast-1a  # ❌

# Missing environment
Name: patterns-alb  # ❌ (which environment?)

# Inconsistent separators
Name: patterns_dev-vpc-public  # ❌ (mixing _ and -)

# Unclear abbreviations
Name: patterns-dev-ps-rt  # ❌ (what is ps?)

# Generic project name
Name: app-dev-vpc  # ❌ (too generic)
```

### ✅ Best Practices
```hcl
# Complete and clear
Name: patterns-dev-vpc-private-subnet-a  # ✅

# Proper project identification
Name: webapp-dev-vpc-private-subnet-a  # ✅

# All components included
Name: patterns-dev-alb  # ✅

# Consistent format
Name: patterns-dev-vpc-public-rt  # ✅

# Clear abbreviations
Name: patterns-dev-vpc-nat-gw-a  # ✅

# Production ready
Name: api-prod-rds-snapshot-final  # ✅
```

## Abbreviation Reference

| Full Term | Abbreviation | Example |
|-----------|--------------|---------|
| Route Table | `rt` | `patterns-dev-vpc-public-rt` |
| Security Group | `sg` | `patterns-dev-alb-sg` |
| Gateway (NAT/IGW) | `gw` | `patterns-dev-vpc-nat-gw-a` |
| Auto Scaling Group | `asg` | `patterns-dev-asg` |
| Launch Template | `lt` | `patterns-dev-lt` |
| Target Group | `tg` | `patterns-dev-tg-http` |
| Database | `db` | `patterns-dev-db` |
| Elastic IP | `eip` | `patterns-dev-vpc-eip-nat-a` |
| Application Load Balancer | `alb` | `patterns-dev-alb` |
| Network Load Balancer | `nlb` | `patterns-dev-nlb` |
| Elastic Block Store | `ebs` | `patterns-dev-ebs-backup` |
| Parameters | `params` | `patterns-dev-db-params` |
| Availability Zone | Single letter | `-a`, `-b` (from `ap-southeast-1a`) |

## Environment Prefixes

| Environment | Prefix | Example |
|-------------|--------|---------|
| Development | `dev` | `patterns-dev-vpc` |
| Staging | `staging` | `patterns-staging-alb` |
| Production | `prod` | `patterns-prod-db` |
| Testing | `test` | `patterns-test-vpc` |
| UAT | `uat` | `patterns-uat-rds` |

## Multi-Region Naming

For multi-region deployments, add region suffix:

```hcl
# Format: <project>-<env>-<resource>-<region>
Examples:
  - patterns-dev-vpc-apse1 (Asia Pacific Southeast 1)
  - webapp-prod-rds-use1 (US East 1)
  - api-staging-s3-euw1 (Europe West 1)
```

### Region Code Reference
- `apse1` = ap-southeast-1 (Singapore)
- `use1` = us-east-1 (N. Virginia)
- `euw1` = eu-west-1 (Ireland)
- `apne1` = ap-northeast-1 (Tokyo)

## Tagging Strategy

In addition to `Name` tag, apply these standard tags:

```hcl
tags = {
  Name        = "<naming-convention>"
  Environment = "dev|staging|prod"
  Pattern     = "P01|P02|P03"
  Project     = "patterns"
  ManagedBy   = "Terraform"
  CostCenter  = "<team-name>"
  Owner       = "<team-email>"
}
```

## References

- [AWS Tagging Best Practices](https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html)
- [Terraform Naming Conventions](https://www.terraform-best-practices.com/naming)
- Project Copilot Instructions: `.github/copilot-instructions.md`

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-01-09 | Initial naming convention document |
| 1.1.0 | 2026-01-09 | Made project name mandatory in all resource names |

---

**Last Updated:** January 9, 2026  
**Maintained By:** Infrastructure Team
