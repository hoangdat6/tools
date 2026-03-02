---
trigger: model_decision
description: Rules for AWS ECS services in Terraform with security best practices
---

You are an expert in AWS ECS and Terraform infrastructure as code.

Key ECS Terraform Guidelines:

1. IAM Roles and Security
   - Always use task execution roles for ECS tasks with minimal required permissions
   - When running ECS on EC2, assign minimum permissions to EC2 host instances
   - Task-specific permissions should be defined in the task IAM role, not the EC2 instance role

2. Networking Configuration
   - Ensure ECS tasks have proper outbound internet access for pulling images and dependencies
   - Configure appropriate subnets, security groups, and network ACLs
   - For private services, use VPC endpoints to communicate with other AWS services

3. Resource Management
   - Set appropriate hard limits for CPU and memory for all ECS tasks
   - Avoid resource contention by properly sizing task definitions
   - Consider using Fargate for consistent resource allocation without managing EC2 instances

4. High Availability
   - Deploy ECS tasks across multiple Availability Zones for high availability
   - Use service auto-scaling to adjust task count based on load
   - Configure appropriate health checks for container-level monitoring

5. Scaling and Performance
   - Implement dynamic scaling based on metrics like CPU/memory utilization
   - Configure scheduled scaling for predictable workload patterns
   - Set appropriate minimum and maximum service counts

6. Logging and Monitoring
   - Always send container logs to CloudWatch Logs or other logging solutions
   - Enable Container Insights for enhanced monitoring (consider the cost of ~$3.5/ECS service)
   - Create custom CloudWatch metrics when Container Insights is not used

7. Service Discovery
   - Use AWS CloudMap for service discovery within the VPC
   - For external clients, use Application Load Balancers with proper target groups
   - For internal services, use internal ALBs or CloudMap based on requirements

8. Image Management
   - Store Docker images in Amazon ECR rather than public repositories
   - Implement image scanning for vulnerabilities
   - Use proper tagging strategies for image versioning

Code Example for ECS Fargate Service:
```terraform
resource "aws_ecs_cluster" "main" {
  name = "app-cluster"
  
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# Task execution role for ECS
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Task role for application-specific permissions
resource "aws_iam_role" "ecs_task_role" {
  name = "ecs-task-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Attach policies to roles
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "task_s3" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.task_s3_policy.arn
}

# Custom policy for task role
resource "aws_iam_policy" "task_s3_policy" {
  name        = "task-s3-policy"
  description = "Allow ECS task to access specific S3 bucket"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::example-bucket",
          "arn:aws:s3:::example-bucket/*"
        ]
      }
    ]
  })
}

# ECS Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = "app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  
  container_definitions = jsonencode([
    {
      name      = "app"
      image     = "${aws_ecr_repository.app.repository_url}:latest"
      essential = true
      
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/app"
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
      
      environment = [
        {
          name  = "ENVIRONMENT"
          value = "production"
        }
      ]
    }
  ])
}

# Security group for ECS tasks
resource "aws_security_group" "ecs_tasks" {
  name        = "ecs-tasks-sg"
  description = "Allow inbound traffic to ECS tasks"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    protocol        = "tcp"
    from_port       = 8080
    to_port         = 8080
    security_groups = [aws_security_group.lb.id]
  }
  
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS Service with load balancer
resource "aws_ecs_service" "app" {
  name            = "app"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  
  network_configuration {
    subnets          = [aws_subnet.private_a.id, aws_subnet.private_b.id]  # Multiple AZs
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }
  
  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app"
    container_port   = 8080
  }
  
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  
  # Enable service auto scaling
  lifecycle {
    ignore_changes = [desired_count]
  }
}

# Auto scaling for ECS service
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 4
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  name               = "cpu-auto-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace
  
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70
  }
}