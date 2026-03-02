---
trigger: model_decision
description: Rules for AWS IAM services in Terraform with security best practices
---

You are an expert in AWS IAM and Terraform infrastructure as code.

Key IAM Terraform Guidelines:

1. Least Privilege Principle
   - Always assign the minimum permissions necessary for IAM users, roles, and policies
   - Scope permissions to specific resources when possible
   - Use conditions to further restrict when permissions are granted
   - Avoid using wildcard permissions (`*`) in resource ARNs and actions

2. User Authentication and Access
   - Enforce Multi-Factor Authentication (MFA) for all IAM users
   - Organize users into IAM groups for easier permission management
   - Use IAM roles for services rather than embedding credentials

3. Group-Based Access Control
   - Create logical IAM groups based on job functions
   - Assign policies to groups rather than individual users
   - Common group patterns include:
     - Administrator: Full account access
     - Maintainer: Service management without IAM control
     - Developer: Limited read/write access to development resources
     - Viewer: Read-only access to non-sensitive resources

4. Role-Based Service Access
   - Use IAM roles for service-to-service access
   - Define clear trust relationships for who can assume roles
   - Attach appropriate permission policies to roles
   - Use service-linked roles when available

5. Environment Separation
   - Maintain separate user access controls for production environments
   - For production, use dual-role approach:
     - Viewer: For daily monitoring and auditing
     - Administrator/Maintainer/Developer: For approved changes only

Code Example for IAM Best Practices:
```terraform
# IAM User Group for administrators
resource "aws_iam_group" "administrators" {
  name = "Administrators"
}

# IAM User Group for developers
resource "aws_iam_group" "developers" {
  name = "Developers"
}

# IAM User Group for viewers
resource "aws_iam_group" "viewers" {
  name = "Viewers"
}

# Attach AdministratorAccess policy to administrators group
resource "aws_iam_group_policy_attachment" "admin_policy" {
  group      = aws_iam_group.administrators.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Custom policy for developers with limited permissions
resource "aws_iam_policy" "developer_policy" {
  name        = "DeveloperPolicy"
  description = "Custom policy for developers"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
          "cloudwatch:Get*",
          "cloudwatch:List*",
          "s3:Get*",
          "s3:List*",
          "codedeploy:*",
          "codebuild:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "codepipeline:StartPipelineExecution",
          "codepipeline:GetPipelineState",
          "codepipeline:GetPipelineExecution"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:codepipeline:*:*:*"
      }
    ]
  })
}

# Attach developer policy to developers group
resource "aws_iam_group_policy_attachment" "developer_policy_attach" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.developer_policy.arn
}

# Read-only policy for viewers
resource "aws_iam_policy" "viewer_policy" {
  name        = "ViewerPolicy"
  description = "Read-only access policy excluding sensitive services"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
          "rds:Describe*",
          "s3:Get*",
          "s3:List*",
          "cloudwatch:Get*",
          "cloudwatch:List*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "iam:*",
          "organizations:*",
          "secretsmanager:*",
          "billing:*",
          "ce:*"
        ]
        Effect   = "Deny"
        Resource = "*"
      }
    ]
  })
}

# Attach viewer policy to viewers group
resource "aws_iam_group_policy_attachment" "viewer_policy_attach" {
  group      = aws_iam_group.viewers.name
  policy_arn = aws_iam_policy.viewer_policy.arn
}

# Example IAM user
resource "aws_iam_user" "example_user" {
  name = "example-user"
}

# Add user to group
resource "aws_iam_user_group_membership" "example_user_groups" {
  user = aws_iam_user.example_user.name
  
  groups = [
    aws_iam_group.developers.name
  ]
}

# Service Role for EC2 to access S3
resource "aws_iam_role" "ec2_s3_access" {
  name = "ec2-s3-access"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Custom policy for EC2 to access specific S3 bucket
resource "aws_iam_policy" "ec2_s3_policy" {
  name        = "ec2-s3-policy"
  description = "Allow EC2 to access specific S3 bucket"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::specific-bucket",
          "arn:aws:s3:::specific-bucket/*"
        ]
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "ec2_s3_policy_attach" {
  role       = aws_iam_role.ec2_s3_access.name
  policy_arn = aws_iam_policy.ec2_s3_policy.arn
}

# IAM Instance Profile for EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-profile"
  role = aws_iam_role.ec2_s3_access.name
}