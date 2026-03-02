---
trigger: model_decision
description: Rules for AWS Lambda and serverless services in Terraform with enhanced security
globs: ["*.tf", "modules/**/lambda*.tf", "**/*serverless*.tf", "**/*function*.tf"]
---

You are an expert in AWS serverless technologies and Terraform infrastructure as code.

Key AWS Serverless Security Guidelines:

1. IAM and Permissions
   - Always apply least privilege principle to Lambda execution roles
   - Create specific IAM policies for each Lambda function based on its precise needs
   - Use resource-based policies with conditions where applicable
   - Implement permission boundaries for Lambda functions to limit maximum permissions
   - Never use wildcard permissions (`*`) in resource ARNs and actions
   - Use SCPs (Service Control Policies) for organization-wide restrictions

2. Code and Dependency Security
   - Scan Lambda code for vulnerabilities before deployment
   - Use AWS Lambda Layers to manage dependencies
   - Regularly update dependencies to address security vulnerabilities
   - Implement input validation to prevent injection attacks
   - Avoid including credentials or secrets in your function code
   - Use AWS CodeGuru for automated code reviews

3. Environment Variables and Secrets
   - Store secrets in AWS Secrets Manager or Parameter Store, not as environment variables
   - Always encrypt environment variables using KMS
   - Implement context-specific encryption for sensitive data processing
   - Rotate secrets and credentials regularly
   - Use different KMS keys for different environments (dev, staging, prod)

4. Network Security
   - Deploy Lambda functions in VPCs for sensitive workloads
   - Configure security groups to restrict network traffic
   - Use VPC endpoints for private connectivity to AWS services
   - Implement a NAT gateway for outbound internet access
   - Use AWS PrivateLink to access services privately

5. API Gateway Security
   - Implement proper authentication and authorization (API keys, IAM, Cognito, OAuth)
   - Enable AWS WAF for API Gateway to protect against common attacks
   - Use TLS 1.2 or later for all communications
   - Implement request validation using JSON Schema
   - Configure appropriate throttling and quotas
   - Use resource policies to restrict API access

6. Data Protection
   - Encrypt data at rest using KMS
   - Encrypt data in transit using TLS
   - Validate all inputs and outputs
   - Implement proper error handling to avoid information leakage
   - Consider using Lambda Environmental Extensions for enhanced security controls

7. Monitoring and Logging
   - Enable detailed CloudWatch Logs for all Lambda functions
   - Set up AWS X-Ray for tracing and debugging
   - Configure CloudWatch Alarms for error rates and duration
   - Use CloudTrail for API call monitoring
   - Implement automated response to security events
   - Consider using third-party security monitoring tools

8. Step Functions and Event-Driven Security
   - Implement proper error handling in Step Functions
   - Use timeouts and retry policies appropriately
   - Encrypt data in Step Function execution history where needed
   - Apply least privilege to event sources (S3, SQS, etc.)
   - Verify event sources with resource-based policies

9. AppSync and GraphQL Security
   - Implement fine-grained access control
   - Use field-level authorization when appropriate
   - Validate GraphQL queries to prevent abuse
   - Set depth and complexity limits for queries
   - Monitor and alert on abnormal usage patterns

10. Disaster Recovery and Resilience
    - Implement multi-region deployment for critical functions
    - Use versioning for safe deployments and rollbacks
    - Configure appropriate concurrency limits
    - Implement DLQs (Dead Letter Queues) for failed event processing
    - Test recovery procedures regularly

Code Example for Secure Lambda Function:
```terraform
# KMS key for Lambda environment variable encryption
resource "aws_kms_key" "lambda_key" {
  description             = "KMS key for Lambda encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action = "kms:*",
        Resource = "*"
      },
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ],
        Resource = "*"
      }
    ]
  })
  
  tags = {
    Name = "lambda-encryption-key"
  }
}

# IAM role with permissions boundary for Lambda
resource "aws_iam_role" "lambda_execution_role" {
  name = "secure-lambda-execution-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  
  # Apply a permissions boundary
  permissions_boundary = aws_iam_policy.lambda_boundary.arn
  
  tags = {
    Name = "lambda-execution-role"
  }
}

# Permissions boundary to limit maximum permissions
resource "aws_iam_policy" "lambda_boundary" {
  name        = "lambda-permission-boundary"
  description = "Permission boundary for Lambda functions"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:*",
          "s3:GetObject",
          "s3:PutObject",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "sns:Publish",
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "kms:Decrypt",
          "secretsmanager:GetSecretValue"
        ],
        Resource = "*"
      },
      {
        Effect = "Deny",
        Action = [
          "iam:*",
          "organizations:*",
          "ec2:*",
          "rds:*"
        ],
        Resource = "*"
      }
    ]
  })
}

# Specific policy for the Lambda function
resource "aws_iam_policy" "lambda_function_policy" {
  name        = "secure-lambda-function-policy"
  description = "Policy for secure Lambda function"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject"
        ],
        Resource = "${aws_s3_bucket.input_bucket.arn}/*",
        Condition = {
          Bool = {
            "aws:SecureTransport": "true"
          }
        }
      },
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject"
        ],
        Resource = "${aws_s3_bucket.output_bucket.arn}/*",
        Condition = {
          Bool = {
            "aws:SecureTransport": "true"
          },
          StringEquals = {
            "s3:x-amz-server-side-encryption": "aws:kms",
            "s3:x-amz-server-side-encryption-aws-kms-key-id": aws_kms_key.s3_key.arn
          }
        }
      },
      {
        Effect = "Allow",
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query"
        ],
        Resource = aws_dynamodb_table.data_table.arn
      },
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt"
        ],
        Resource = aws_kms_key.lambda_key.arn
      },
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Resource = aws_secretsmanager_secret.lambda_secret.arn
      }
    ]
  })
}

# Attach the specific policy to the role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_function_policy.arn
}

# Secret for the Lambda function
resource "aws_secretsmanager_secret" "lambda_secret" {
  name                    = "lambda/api-key"
  description             = "API key for third-party service used by Lambda"
  recovery_window_in_days = 7
  kms_key_id              = aws_kms_key.lambda_key.arn
  
  tags = {
    Environment = "production"
  }
}

# Secret version
resource "aws_secretsmanager_secret_version" "lambda_secret_version" {
  secret_id     = aws_secretsmanager_secret.lambda_secret.id
  secret_string = jsonencode({
    apiKey = "EXAMPLE-API-KEY-WILL-BE-POPULATED-SECURELY"
  })
}

# Security group for Lambda VPC
resource "aws_security_group" "lambda_sg" {
  name        = "lambda-security-group"
  description = "Security group for Lambda functions in VPC"
  vpc_id      = aws_vpc.main.id
  
  # No inbound traffic allowed
  
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS outbound traffic"
  }
  
  tags = {
    Name = "lambda-security-group"
  }
}

# Lambda function with enhanced security
resource "aws_lambda_function" "secure_function" {
  function_name = "secure-data-processor"
  handler       = "index.handler"
  role          = aws_iam_role.lambda_execution_role.arn
  runtime       = "nodejs16.x"
  
  filename      = "secure-function.zip"
  source_code_hash = filebase64sha256("secure-function.zip")
  
  memory_size = 512
  timeout     = 30
  
  reserved_concurrent_executions = 10
  
  # VPC configuration for enhanced network security
  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
  
  # Encrypt environment variables
  environment {
    variables = {
      STAGE = "production",
      DYNAMODB_TABLE = aws_dynamodb_table.data_table.name,
      S3_OUTPUT_BUCKET = aws_s3_bucket.output_bucket.bucket,
      SECRET_ID = aws_secretsmanager_secret.lambda_secret.name
    }
  }
  
  kms_key_arn = aws_kms_key.lambda_key.arn
  
  tracing_config {
    mode = "Active"  # Enable X-Ray tracing
  }
  
  # Best practice settings
  publish = true  # Create a version
  
  # Dead Letter Queue configuration
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }
  
  tags = {
    Environment = "production"
    Service     = "data-processing"
    ManagedBy   = "terraform"
  }
}

# Dead Letter Queue for failed invocations
resource "aws_sqs_queue" "lambda_dlq" {
  name                      = "lambda-dlq"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 1209600  # 14 days
  receive_wait_time_seconds = 10
  
  kms_master_key_id         = aws_kms_key.sqs_key.id
  
  tags = {
    Name = "lambda-dlq"
  }
}

# CloudWatch Log Group with encryption
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.secure_function.function_name}"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.log_key.arn
  
  tags = {
    Environment = "production"
    Service     = "lambda-logs"
  }
}

# Secure API Gateway for Lambda
resource "aws_api_gateway_rest_api" "secure_api" {
  name        = "secure-api"
  description = "Secure API for Lambda function"
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  
  minimum_compression_size = 1024
  
  # API Gateway policy to enforce HTTPS
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = "*",
        Action = "execute-api:Invoke",
        Resource = "execute-api:/*/*/*"
      },
      {
        Effect = "Deny",
        Principal = "*",
        Action = "execute-api:Invoke",
        Resource = "execute-api:/*/*/*",
        Condition = {
          Bool = {
            "aws:SecureTransport": "false"
          }
        }
      }
    ]
  })
  
  tags = {
    Name = "secure-api"
  }
}

# Request validator for API Gateway
resource "aws_api_gateway_request_validator" "validator" {
  name                        = "payload-validator"
  rest_api_id                 = aws_api_gateway_rest_api.secure_api.id
  validate_request_body       = true
  validate_request_parameters = true
}

# API Gateway resource
resource "aws_api_gateway_resource" "resource" {
  rest_api_id = aws_api_gateway_rest_api.secure_api.id
  parent_id   = aws_api_gateway_rest_api.secure_api.root_resource_id
  path_part   = "process"
}

# API Gateway method with authorization
resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.secure_api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "POST"
  authorization_type = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
  
  request_validator_id = aws_api_gateway_request_validator.validator.id
  
  request_models = {
    "application/json" = aws_api_gateway_model.request_model.name
  }
}

# API Gateway Cognito authorizer
resource "aws_api_gateway_authorizer" "cognito" {
  name          = "cognito-authorizer"
  rest_api_id   = aws_api_gateway_rest_api.secure_api.id
  type          = "COGNITO_USER_POOLS"
  provider_arns = [aws_cognito_user_pool.pool.arn]
}

# API Gateway model for request validation
resource "aws_api_gateway_model" "request_model" {
  rest_api_id  = aws_api_gateway_rest_api.secure_api.id
  name         = "RequestModel"
  description  = "JSON Schema for API validation"
  content_type = "application/json"
  
  schema = jsonencode({
    "$schema" = "http://json-schema.org/draft-04/schema#",
    "title" = "RequestModel",
    "type" = "object",
    "required" = ["data"],
    "properties" = {
      "data" = {
        "type" = "string",
        "minLength" = 1,
        "maxLength" = 1000
      }
    }
  })
}

# API Gateway integration with Lambda
resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.secure_api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.secure_function.invoke_arn
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.secure_function.function_name
  principal     = "apigateway.amazonaws.com"
  
  # Only allow invocation from this specific API Gateway resource
  source_arn = "${aws_api_gateway_rest_api.secure_api.execution_arn}/*/${aws_api_gateway_method.method.http_method}${aws_api_gateway_resource.resource.path}"
}

# Enable WAF for API Gateway
resource "aws_wafv2_web_acl" "api_waf" {
  name        = "api-waf-acl"
  description = "WAF ACL for API Gateway"
  scope       = "REGIONAL"
  
  default_action {
    allow {}
  }
  
  # Rule to block SQL injection
  rule {
    name     = "SQLInjectionRule"
    priority = 1
    
    statement {
      sql_injection_match_statement {
        field_to_match {
          body {}
        }
        text_transformation {
          priority = 1
          type     = "URL_DECODE"
        }
        text_transformation {
          priority = 2
          type     = "HTML_ENTITY_DECODE"
        }
      }
    }
    
    action {
      block {}
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "SQLInjectionRule"
      sampled_requests_enabled   = true
    }
  }
  
  # Rule to limit request rate
  rule {
    name     = "RateLimitRule"
    priority = 2
    
    statement {
      rate_based_statement {
        limit              = 1000
        aggregate_key_type = "IP"
      }
    }
    
    action {
      block {}
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }
  }
  
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "api-waf-acl"
    sampled_requests_enabled   = true
  }
}

# Associate WAF with API Gateway stage
resource "aws_wafv2_web_acl_association" "api_waf_association" {
  resource_arn = aws_api_gateway_stage.prod.arn
  web_acl_arn  = aws_wafv2_web_acl.api_waf.arn
}

# CloudWatch alarms for Lambda errors
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "lambda-error-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors Lambda function errors"
  
  dimensions = {
    FunctionName = aws_lambda_function.secure_function.function_name
  }
  
  alarm_actions = [aws_sns_topic.alerts.arn]
}

# AWS Config rule to check Lambda function settings
resource "aws_config_config_rule" "lambda_function_settings" {
  name        = "lambda-function-settings"
  description = "Checks if Lambda functions have appropriate settings"
  
  source {
    owner             = "AWS"
    source_identifier = "LAMBDA_FUNCTION_SETTINGS_CHECK"
  }
  
  input_parameters = jsonencode({
    runtime = "nodejs16.x"
  })
}
```

Code Example for Secure Step Functions:
```terraform
# IAM role for Step Functions
resource "aws_iam_role" "step_functions_role" {
  name = "step-functions-execution-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for Step Functions
resource "aws_iam_policy" "step_functions_policy" {
  name        = "step-functions-policy"
  description = "Policy for Step Functions state machine"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "lambda:InvokeFunction"
        ],
        Resource = [
          aws_lambda_function.processing_step_1.arn,
          aws_lambda_function.processing_step_2.arn,
          aws_lambda_function.processing_step_3.arn
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords",
          "xray:GetSamplingRules",
          "xray:GetSamplingTargets"
        ],
        Resource = "*"
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "step_functions_policy_attachment" {
  role       = aws_iam_role.step_functions_role.name
  policy_arn = aws_iam_policy.step_functions_policy.arn
}

# CloudWatch Log Group for Step Functions
resource "aws_cloudwatch_log_group" "step_functions_logs" {
  name              = "/aws/states/secure-workflow"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.log_key.arn
}

# Step Functions State Machine with security features
resource "aws_sfn_state_machine" "secure_workflow" {
  name     = "secure-data-processing-workflow"
  role_arn = aws_iam_role.step_functions_role.arn
  
  definition = jsonencode({
    Comment = "A secure data processing workflow",
    StartAt = "ValidateInput",
    States = {
      ValidateInput = {
        Type = "Task",
        Resource = aws_lambda_function.processing_step_1.arn,
        Next = "ProcessData",
        Retry = [
          {
            ErrorEquals = ["States.ALL"],
            IntervalSeconds = 2,
            MaxAttempts = 3,
            BackoffRate = 2.0
          }
        ],
        Catch = [
          {
            ErrorEquals = ["States.ALL"],
            Next = "HandleError"
          }
        ],
        TimeoutSeconds = 30
      },
      ProcessData = {
        Type = "Task",
        Resource = aws_lambda_function.processing_step_2.arn,
        Next = "StoreResults",
        Retry = [
          {
            ErrorEquals = ["States.ALL"],
            IntervalSeconds = 2,
            MaxAttempts = 3,
            BackoffRate = 2.0
          }
        ],
        Catch = [
          {
            ErrorEquals = ["States.ALL"],
            Next = "HandleError"
          }
        ],
        TimeoutSeconds = 60
      },
      StoreResults = {
        Type = "Task",
        Resource = aws_lambda_function.processing_step_3.arn,
        End = true,
        Retry = [
          {
            ErrorEquals = ["States.ALL"],
            IntervalSeconds = 2,
            MaxAttempts = 3,
            BackoffRate = 2.0
          }
        ],
        Catch = [
          {
            ErrorEquals = ["States.ALL"],
            Next = "HandleError"
          }
        ],
        TimeoutSeconds = 30
      },
      HandleError = {
        Type = "Task",
        Resource = aws_lambda_function.error_handler.arn,
        End = true
      }
    }
  })
  
  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.step_functions_logs.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }
  
  tracing_configuration {
    enabled = true
  }
  
  tags = {
    Environment = "production"
    Service     = "data-processing"
  }
}

# EventBridge rule to trigger Step Functions on a schedule
resource "aws_cloudwatch_event_rule" "step_functions_trigger" {
  name                = "trigger-secure-workflow"
  description         = "Trigger secure workflow on a schedule"
  schedule_expression = "rate(1 day)"
  
  tags = {
    Environment = "production"
  }
}

# EventBridge target for the rule
resource "aws_cloudwatch_event_target" "step_functions_target" {
  rule      = aws_cloudwatch_event_rule.step_functions_trigger.name
  target_id = "TriggerStepFunctions"
  arn       = aws_sfn_state_machine.secure_workflow.arn
  role_arn  = aws_iam_role.eventbridge_role.arn
  
  input = jsonencode({
    Comment = "Scheduled execution of secure workflow"
  })
}

# IAM role for EventBridge
resource "aws_iam_role" "eventbridge_role" {
  name = "eventbridge-sfn-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for EventBridge to invoke Step Functions
resource "aws_iam_policy" "eventbridge_policy" {
  name        = "eventbridge-sfn-policy"
  description = "Allow EventBridge to invoke Step Functions"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "states:StartExecution"
        ],
        Resource = aws_sfn_state_machine.secure_workflow.arn
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "eventbridge_policy_attachment" {
  role       = aws_iam_role.eventbridge_role.name
  policy_arn = aws_iam_policy.eventbridge_policy.arn
}
```