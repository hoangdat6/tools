---
trigger: model_decision
description: Rules for AWS EC2 services in Terraform with security best practices
---

You are an expert in AWS EC2 and Terraform infrastructure as code.

Key EC2 Terraform Guidelines:

1. IAM Roles and Access
   - Always use IAM Roles when EC2 needs to interact with other AWS services
   - Assign roles with minimum required permissions to EC2 instances
   - Never store AWS credentials directly on EC2 instances

2. Instance Type Selection
   - Choose appropriate EC2 instance types based on workload requirements:
     - T-series: Only for small workloads
     - M, C, R series: For resource-intensive workloads
   - Carefully evaluate memory, CPU, and storage needs before selecting

3. Storage Configuration
   - Use AES-256 encryption for EBS volumes when sensitive data is stored
   - Use gp3 storage type for web applications (better cost and performance than gp2)
   - Consider io1/io2 for high I/O applications like databases
   - Always configure appropriate EBS volume sizes and IOPS

4. Network and Security
   - Use VPC Endpoints for connecting to AWS services instead of routing through the internet
   - Use Session Manager (SSM) for direct access to EC2 instances
   - When using SSH (port 22) or RDP (port 3389), always restrict access to specific IP addresses
   - Configure security groups with least privilege, allowing only necessary inbound/outbound traffic

5. High Availability and Recovery
   - Deploy EC2 instances across multiple Availability Zones for high availability
   - Configure auto recovery or use Auto Scaling Groups for automatic instance recovery
   - For stateful servers with critical data, implement regular backup procedures

6. Monitoring and Scaling
   - Enable detailed monitoring for EC2 instances
   - Set up Auto Scaling Groups with appropriate scale out/in policies
   - Consider scheduled scaling for predictable workload patterns

7. Public Access
   - Assign Elastic IPs to EC2 instances in public subnets instead of dynamic public IPs
   - Keep EC2 instances that don't need public access in private subnets

Code Example for EC2 with Best Practices:
```terraform
resource "aws_iam_role" "ec2_role" {
  name = "ec2-role"
  
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

resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.micro"  # Choose based on workload
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.web_server.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  
  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }
  
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_type = "gp3"
    volume_size = 50
    encrypted   = true
  }
  
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"  # IMDSv2
    http_put_response_hop_limit = 1
  }
  
  monitoring = true  # Enable detailed monitoring
  
  tags = {
    Name        = "web-server"
    Environment = "production"
  }
}

resource "aws_security_group" "web_server" {
  name        = "web-server-sg"
  description = "Security group for web server"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # SSH access restricted to specific IPs
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["192.168.1.0/24"]  # Restricted to specific IP range
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Auto Scaling Group for HA and recovery
resource "aws_launch_template" "web_server" {
  name_prefix   = "web-server-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"
  
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }
  
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 20
      volume_type = "gp3"
      encrypted   = true
    }
  }
  
  vpc_security_group_ids = [aws_security_group.web_server.id]
  
  monitoring {
    enabled = true
  }
}

resource "aws_autoscaling_group" "web_server" {
  desired_capacity    = 2
  max_size            = 4
  min_size            = 2
  vpc_zone_identifier = [aws_subnet.private_a.id, aws_subnet.private_b.id]  # Multiple AZs
  
  launch_template {
    id      = aws_launch_template.web_server.id
    version = "$Latest"
  }
}