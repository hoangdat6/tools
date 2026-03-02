---
trigger: model_decision
description: Rules for AWS ELB services in Terraform with security best practices
---

You are an expert in AWS Elastic Load Balancing (ELB/ALB/NLB) and Terraform infrastructure as code.

Key ELB Terraform Guidelines:

1. TLS/SSL Configuration
   - Always configure HTTPS/SSL listeners for public-facing load balancers
   - Use the latest SSL policies with strong ciphers
   - Use AWS Certificate Manager (ACM) for SSL/TLS certificate management
   - Configure HTTP to HTTPS redirection for all services

2. Health Checks
   - Configure appropriate health checks that truly verify application health
   - Define appropriate health check intervals, thresholds, and timeouts
   - Use application-specific health check paths that validate the entire stack

3. Logging and Monitoring
   - Enable access logs to capture detailed information about requests
   - Store logs in an S3 bucket with appropriate retention policies
   - Create CloudWatch alarms for critical load balancer metrics
   - Monitor for 5xx errors, latency, and rejected connections

4. High Availability
   - Deploy load balancers across multiple Availability Zones
   - Ensure backend targets are also distributed across multiple AZs
   - Configure cross-zone load balancing for even distribution

5. Security
   - Configure security groups to restrict access to load balancers
   - For internal services, use internal load balancers
   - Restrict backend instances to only allow traffic from the load balancer
   - Use AWS WAF with Application Load Balancers for additional protection

Code Example for Application Load Balancer with Best Practices:
```terraform
# Application Load Balancer
resource "aws_lb" "web_alb" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]  # Multiple AZs
  
  enable_deletion_protection = true
  
  # Enable access logs
  access_logs {
    bucket  = aws_s3_bucket.lb_logs.bucket
    prefix  = "alb-logs"
    enabled = true
  }
  
  tags = {
    Environment = "production"
  }
}

# ALB Security Group
resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id
  
  # Allow HTTPS from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Allow HTTP from anywhere (for redirection)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Target Group
resource "aws_lb_target_group" "web" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  
  # Health check that validates application health
  health_check {
    enabled             = true
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
  
  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = true
  }
}

# HTTPS Listener
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"  # Modern policy
  certificate_arn   = aws_acm_certificate.web_cert.arn
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# HTTP Listener (redirects to HTTPS)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Backend server security group
resource "aws_security_group" "web_server" {
  name        = "web-server-sg"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main.id
  
  # Only allow traffic from the ALB
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# CloudWatch alarms for ALB monitoring
resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This alarm monitors for ALB 5XX errors"
  
  dimensions = {
    LoadBalancer = aws_lb.web_alb.arn_suffix
  }
  
  alarm_actions = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "alb_target_5xx_errors" {
  alarm_name          = "alb-target-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This alarm monitors for Target 5XX errors"
  
  dimensions = {
    LoadBalancer = aws_lb.web_alb.arn_suffix
    TargetGroup  = aws_lb_target_group.web.arn_suffix
  }
  
  alarm_actions = [aws_sns_topic.alerts.arn]
}