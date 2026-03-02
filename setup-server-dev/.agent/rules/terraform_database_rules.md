---
trigger: model_decision
description: Rules for AWS Database services (RDS, DynamoDB, etc.) in Terraform with security best practices
globs: ["*.tf", "modules/**/rds*.tf", "**/*database*.tf", "**/*dynamodb*.tf"]
---

You are an expert in AWS database services and Terraform infrastructure as code.

Key AWS Database Terraform Guidelines:

1. Encryption and Data Protection
   - Always enable encryption at rest for all database services
   - Use customer-managed KMS keys rather than AWS-managed keys for better control
   - For RDS, enable storage encryption using KMS
   - For DynamoDB, enable encryption at rest
   - For ElastiCache, enable encryption in transit and at rest
   - Implement automated backup solutions with encryption
   - Enable point-in-time recovery for DynamoDB tables

2. Network Security
   - Deploy database instances in private subnets with no direct public access
   - Use security groups that limit access to specific sources
   - For RDS, set publicly_accessible = false (default) for all instances
   - Use VPC endpoints to access DynamoDB without internet exposure
   - Use AWS PrivateLink for secure access to your databases from on-premises
   - Implement strict NACLs as additional network security layer

3. Authentication and Access Control
   - Use IAM authentication for RDS when applicable
   - Implement specific IAM policies for DynamoDB with resource-level permissions
   - Use appropriate parameter groups to enforce security settings
   - Use strong, rotating credentials for database master users
   - Store database credentials in AWS Secrets Manager
   - Do not hardcode credentials in application code or Terraform files
   - Implement temporary credentials with limited lifetime when applicable

4. Audit and Monitoring
   - Enable CloudTrail for all database API operations
   - Configure enhanced monitoring for RDS instances
   - Enable Performance Insights for RDS to detect unusual access patterns
   - Publish database logs to CloudWatch Logs
   - Set up CloudWatch Alarms for anomalous behavior
   - Consider using GuardDuty for additional threat detection
   - Configure AWS Config rules to track compliance

5. High Availability and Resilience
   - Deploy Multi-AZ configurations for production databases
   - Implement read replicas for scalability and disaster recovery
   - Create appropriate backup retention periods (at least 30 days for production)
   - Test recovery procedures regularly
   - Implement cross-region solutions for critical workloads
   - Use Global Tables for DynamoDB in multi-region applications

6. Database-specific Security Settings
   - For RDS, disable public snapshots
   - Configure appropriate database parameters for security (e.g., SSL enforcement)
   - Implement least privilege principles for database users
   - Regularly rotate database credentials
   - Implement deletion protection for production databases
   - Use RDS Proxy to enforce IAM authentication and reduce exposure

Code Example for RDS with Enhanced Security:
```terraform
# KMS key for RDS encryption
resource "aws_kms_key" "rds_encryption_key" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  policy                  = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "Allow RDS to use the key",
      "Effect": "Allow",
      "Principal": {
        "Service": "rds.amazonaws.com"
      },
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": "*"
    }
  ]
}
EOF

  tags = {
    Name = "rds-encryption-key"
  }
}

# Generate a random password for RDS master user
resource "random_password" "rds_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Store the password in Secrets Manager
resource "aws_secretsmanager_secret" "rds_credentials" {
  name                    = "prod/db/credentials"
  description             = "RDS master user credentials"
  recovery_window_in_days = 7
  kms_key_id              = aws_kms_key.rds_encryption_key.arn
  
  tags = {
    Environment = "production"
  }
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id     = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.rds_password.result
    engine   = "mysql"
    host     = aws_db_instance.main.address
    port     = aws_db_instance.main.port
    dbname   = aws_db_instance.main.name
  })
}

# Parameter group with secure configurations
resource "aws_db_parameter_group" "mysql_secure" {
  name        = "mysql-secure-params"
  family      = "mysql8.0"
  description = "MySQL parameter group with security settings"
  
  parameter {
    name  = "require_secure_transport"
    value = "ON"
  }
  
  parameter {
    name  = "log_output"
    value = "FILE"
  }
  
  parameter {
    name  = "general_log"
    value = "1"
  }
  
  parameter {
    name  = "slow_query_log"
    value = "1"
  }
  
  parameter {
    name  = "log_queries_not_using_indexes"
    value = "1"
  }
  
  parameter {
    name  = "log_error_verbosity"
    value = "3"
  }
}

# Option group for MySQL audit
resource "aws_db_option_group" "mysql_audit" {
  name                     = "mysql-audit"
  option_group_description = "MySQL option group with audit plugin"
  engine_name              = "mysql"
  major_engine_version     = "8.0"
  
  option {
    option_name = "MARIADB_AUDIT_PLUGIN"
    
    option_settings {
      name  = "SERVER_AUDIT_EVENTS"
      value = "CONNECT,QUERY,TABLE,QUERY_DDL,QUERY_DML,QUERY_DCL"
    }
    
    option_settings {
      name  = "SERVER_AUDIT_LOGGING"
      value = "ON"
    }
  }
}

# Security group for RDS
resource "aws_security_group" "rds" {
  name        = "rds-sg"
  description = "Security group for RDS instances"
  vpc_id      = aws_vpc.main.id
  
  # Allow MySQL/Aurora access only from application servers
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_servers.id]
    description     = "MySQL access from application servers"
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  
  tags = {
    Name = "rds-security-group"
  }
}

# Subnet group for RDS spanning multiple AZs
resource "aws_db_subnet_group" "main" {
  name       = "main-db-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id, aws_subnet.private_c.id]
  
  tags = {
    Name = "Main DB subnet group"
  }
}

# RDS Instance with security configurations
resource "aws_db_instance" "main" {
  identifier                  = "production-db"
  allocated_storage           = 100
  max_allocated_storage       = 1000
  storage_type                = "gp3"
  engine                      = "mysql"
  engine_version              = "8.0.28"
  instance_class              = "db.t3.large"
  db_name                     = "appdb"
  username                    = "admin"
  password                    = random_password.rds_password.result
  parameter_group_name        = aws_db_parameter_group.mysql_secure.name
  option_group_name           = aws_db_option_group.mysql_audit.name
  db_subnet_group_name        = aws_db_subnet_group.main.name
  vpc_security_group_ids      = [aws_security_group.rds.id]
  storage_encrypted           = true
  kms_key_id                  = aws_kms_key.rds_encryption_key.arn
  backup_retention_period     = 30
  backup_window               = "03:00-05:00"
  maintenance_window          = "sun:05:00-sun:07:00"
  auto_minor_version_upgrade  = true
  copy_tags_to_snapshot       = true
  deletion_protection         = true
  skip_final_snapshot         = false
  final_snapshot_identifier   = "production-db-final-snapshot"
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
  performance_insights_enabled    = true
  performance_insights_retention_period = 7
  performance_insights_kms_key_id = aws_kms_key.rds_encryption_key.arn
  multi_az                    = true
  publicly_accessible         = false
  ca_cert_identifier          = "rds-ca-2019"  # Latest CA certificate
  monitoring_interval         = 60  # Enhanced monitoring (in seconds)
  monitoring_role_arn         = aws_iam_role.rds_monitoring.arn
  iam_database_authentication_enabled = true
  
  lifecycle {
    prevent_destroy = true
  }
  
  tags = {
    Name        = "production-database"
    Environment = "production"
    Backup      = "true"
  }
}

# IAM role for Enhanced Monitoring
resource "aws_iam_role" "rds_monitoring" {
  name = "rds-monitoring-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# CloudWatch Alarms for RDS
resource "aws_cloudwatch_metric_alarm" "rds_cpu_utilization" {
  alarm_name          = "rds-high-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors RDS CPU utilization"
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }
  
  alarm_actions = [aws_sns_topic.db_alarms.arn]
}

# Example of DynamoDB with security configurations
resource "aws_dynamodb_table" "secure_table" {
  name           = "secure-data-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  
  attribute {
    name = "id"
    type = "S"
  }
  
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb_encryption_key.arn
  }
  
  point_in_time_recovery {
    enabled = true
  }
  
  tags = {
    Name        = "secure-dynamodb-table"
    Environment = "production"
  }
}

# VPC Endpoint for DynamoDB
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.region}.dynamodb"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem"
        ]
        Effect    = "Allow"
        Resource  = aws_dynamodb_table.secure_table.arn
        Principal = "*"
      }
    ]
  })
  
  route_table_ids = [aws_route_table.private.id]
  
  tags = {
    Name = "dynamodb-vpc-endpoint"
  }
}

# AWS Backup plan for databases
resource "aws_backup_plan" "database_backup" {
  name = "database-backup-plan"
  
  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 1 * * ? *)"
    
    lifecycle {
      delete_after = 30
    }
  }
  
  advanced_backup_setting {
    resource_type   = "RDS"
    backup_options = {
      WindowsVSS = "enabled"
    }
  }
}

resource "aws_backup_selection" "database_backup" {
  name          = "database-backup-selection"
  iam_role_arn  = aws_iam_role.backup_role.arn
  plan_id       = aws_backup_plan.database_backup.id
  
  resources = [
    aws_db_instance.main.arn,
    aws_dynamodb_table.secure_table.arn
  ]
}
```

Code Example for DynamoDB with Global Tables:
```terraform
# KMS key for DynamoDB encryption
resource "aws_kms_key" "dynamodb_encryption" {
  provider                = aws.primary
  description             = "KMS key for DynamoDB encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  
  tags = {
    Name = "dynamodb-encryption-key"
  }
}

# Primary region table
resource "aws_dynamodb_table" "global_primary" {
  provider       = aws.primary
  name           = "global-data-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  stream_enabled = true
  stream_view_type = "NEW_AND_OLD_IMAGES"  # Required for global tables
  
  attribute {
    name = "id"
    type = "S"
  }
  
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb_encryption.arn
  }
  
  point_in_time_recovery {
    enabled = true
  }
  
  tags = {
    Name        = "global-dynamodb-table"
    Environment = "production"
    Replicated  = "true"
  }
}

# Secondary region table
resource "aws_dynamodb_table" "global_secondary" {
  provider       = aws.secondary
  name           = "global-data-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  stream_enabled = true
  stream_view_type = "NEW_AND_OLD_IMAGES"
  
  attribute {
    name = "id"
    type = "S"
  }
  
  server_side_encryption {
    enabled = true
    # Create a separate KMS key in the secondary region
    kms_key_arn = aws_kms_key.dynamodb_encryption_secondary.arn
  }
  
  point_in_time_recovery {
    enabled = true
  }
  
  tags = {
    Name        = "global-dynamodb-table"
    Environment = "production"
    Replicated  = "true"
  }
}

# Create global table for both regions
resource "aws_dynamodb_global_table" "global" {
  depends_on = [
    aws_dynamodb_table.global_primary,
    aws_dynamodb_table.global_secondary
  ]
  
  name = "global-data-table"
  
  replica {
    region_name = var.primary_region
  }
  
  replica {
    region_name = var.secondary_region
  }
}

# IAM policy for access to DynamoDB
resource "aws_iam_policy" "dynamodb_access" {
  name        = "dynamodb-secure-access"
  description = "Policy for secure access to DynamoDB tables"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "dynamodb:GetItem",
          "dynamodb:BatchGetItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.global_primary.arn
        ]
        # Add condition to enforce encryption in transit
        Condition = {
          Bool = {
            "aws:SecureTransport": "true"
          }
        }
      },
      {
        Effect   = "Allow"
        Action   = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:BatchWriteItem"
        ]
        Resource = [
          aws_dynamodb_table.global_primary.arn
        ]
        # Additional conditions for write operations
        Condition = {
          Bool = {
            "aws:SecureTransport": "true"
          }
          StringEquals = {
            "aws:PrincipalTag/Role": "DataWriter"
          }
        }
      }
    ]
  })
}
```