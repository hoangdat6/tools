---
trigger: model_decision
description: Rules for AWS VPC services in Terraform with security best practices
---

You are an expert in AWS VPC networking and Terraform infrastructure as code.

**Key Principles to Apply for VPC Infrastructure:**
- **Accuracy:** Ensure Terraform resources accurately reflect the intended infrastructure design
- **Modularity:** Prefer reusable modules for common patterns (VPC, subnets, routing)
- **Versioning:** Lock provider versions to avoid breaking changes
- **Variables:** Parameterize configuration values (CIDR blocks, names, AZs) rather than hardcoding
- **Security:** Implement defense-in-depth with multiple security layers
- **High Availability:** Deploy network resources across multiple AZs
- **Documentation:** Tag resources consistently and document network design

Key AWS VPC Terraform Guidelines:

1. VPC Design and Architecture
   - Design VPCs with proper isolation and segmentation (minimum 3 tiers: Ingress, Application, Database)
   - Use appropriate CIDR blocks with sufficient IP space for future growth
   - Split CIDR blocks logically across subnets with room for expansion
   - Implement a consistent naming convention for all VPC resources
   - Consider multi-account network architectures for large organizations
   - Use AWS Transit Gateway for complex multi-VPC connectivity requirements
   - For custom VPCs, never use the default VPC for production workloads

2. Subnet Organization and Isolation
   - Create separate subnets for different tiers (public, private, database)
   - Distribute subnets across multiple Availability Zones for high availability
   - Implement proper tagging for subnets including purpose, tier, and environment
   - Consider dedicated subnets for specific workload types (e.g., EKS clusters)
   - Use more restrictive NACLs for sensitive subnets (e.g., database tier)
   - Never make database or backend application subnets public
   - Use descriptive naming conventions to clearly identify subnet purpose

3. Route Tables and Traffic Flow
   - Create separate route tables for different subnet tiers
   - Only associate public subnets with routes to Internet Gateway
   - Use NAT Gateways or NAT Instances for private subnet internet access
   - Place NAT Gateways in multiple AZs for high availability
   - Consider Transit Gateway for complex routing between multiple VPCs
   - Implement route propagation for dynamic routing when appropriate
   - Use proper tagging for route tables to indicate their purpose
   - Never share a single route table across multiple subnets with different purposes

4. Security Groups and NACLs
   - Implement defense in depth with both Security Groups and NACLs
   - Use Security Groups as the primary access control mechanism for "allow" rules
   - Use NACLs as a secondary defensive boundary for subnets, especially for "deny" rules
   - Follow least privilege principle for all Security Group rules
   - Avoid overly permissive rules (e.g., 0.0.0.0/0) except where absolutely necessary
   - Reference security groups as sources instead of IP ranges where possible
   - Document purpose for each security group rule
   - Implement proper tagging for security groups
   - Use independent NACLs for each subnet tier at minimum

5. VPC Endpoints
   - Use VPC Endpoints to privately access AWS services without internet exposure
   - Implement Gateway Endpoints for S3 and DynamoDB
   - Use Interface Endpoints (AWS PrivateLink) for other AWS services
   - Restrict VPC Endpoint access with appropriate endpoint policies
   - Place endpoints in multiple AZs for high availability
   - Configure security groups to restrict access to endpoints
   - Ensure endpoint policies don't allow public exposure of endpoints

6. VPC Peering and Transit Gateway
   - Use VPC Peering for simple VPC-to-VPC connectivity
   - Be aware of transitive routing limitations with VPC Peering
   - Consider Transit Gateway for more complex network topologies (4+ VPCs)
   - Ensure proper security group and route table configuration for peered VPCs
   - Document all peering connections and their purpose
   - Implement proper tagging for peering resources
   - When multiple on-premise locations communicate with multiple VPCs, use Transit Gateway

7. Network Monitoring and Logging
   - Enable VPC Flow Logs to capture IP traffic information
   - Configure Flow Logs to publish to CloudWatch Logs or S3
   - Implement log retention policies appropriate for compliance requirements
   - Set up CloudWatch alarms for suspicious traffic patterns
   - Consider using AWS Network Firewall for advanced traffic filtering
   - Implement GuardDuty for threat detection
   - Enable AWS Config for network compliance monitoring
   - Configure AWS Firewall Manager for multi-account environments

8. Bastion Hosts and NAT Instances
   - For bastion hosts, use Elastic IP and restrict SSH access to specific source IPs
   - For NAT instances, use Elastic IP and allow traffic only from VPC CIDR blocks
   - Disable source/destination checking on NAT instances
   - Deploy independent NAT instances or gateways per AZ for high availability
   - Implement proper security groups for bastion hosts and NAT instances
   - Consider using Systems Manager Session Manager as an alternative to bastion hosts

9. VPN and Direct Connect
   - For on-premise to AWS communication, implement encrypted VPN Site-to-Site
   - Ensure VPN connections have at least 2 tunnels for high availability
   - For critical workloads, consider Direct Connect with VPN backup
   - Implement proper routing between on-premise and AWS resources
   - Test failover scenarios regularly
   - Document network configurations and IP address spaces

10. Cleanup and Cost Optimization
    - Delete unused Virtual Private Gateways (VGW) and Internet Gateways (IGW)
    - Use shared NAT Gateways where appropriate to reduce costs
    - Implement proper tagging for network resources to track costs
    - Consider VPC Endpoint costs compared to NAT Gateway data transfer costs
    - Regularly review and clean up unused network resources
    - Use Transit Gateway when the number of peering connections becomes costly
    - Optimize CIDR block allocations to minimize address space waste

Code Example for Secure VPC Architecture:
```terraform
# Define VPC with secure CIDR block
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  # Enable IPv6 if needed
  assign_generated_ipv6_cidr_block = false
  
  tags = {
    Name        = "main-vpc"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# Public subnets in multiple AZs
resource "aws_subnet" "public" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone = var.availability_zones[count.index]
  
  # Auto-assign public IP to resources in public subnets
  map_public_ip_on_launch = true
  
  tags = {
    Name        = "public-subnet-${var.availability_zones[count.index]}"
    Environment = "production"
    Tier        = "public"
    ManagedBy   = "terraform"
  }
}

# Private application subnets in multiple AZs
resource "aws_subnet" "private_app" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + length(var.availability_zones))
  availability_zone = var.availability_zones[count.index]
  
  tags = {
    Name        = "private-app-subnet-${var.availability_zones[count.index]}"
    Environment = "production"
    Tier        = "private-app"
    ManagedBy   = "terraform"
  }
}

# Database subnets in multiple AZs
resource "aws_subnet" "private_db" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 2 * length(var.availability_zones))
  availability_zone = var.availability_zones[count.index]
  
  tags = {
    Name        = "private-db-subnet-${var.availability_zones[count.index]}"
    Environment = "production"
    Tier        = "private-db"
    ManagedBy   = "terraform"
  }
}

# Internet Gateway for public internet access
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name        = "main-igw"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# Elastic IPs for NAT Gateways (one per AZ for high availability)
resource "aws_eip" "nat" {
  count  = length(var.availability_zones)
  domain = "vpc"
  
  tags = {
    Name        = "nat-eip-${var.availability_zones[count.index]}"
    Environment = "production"
    ManagedBy   = "terraform"
  }
  
  depends_on = [aws_internet_gateway.main]
}

# NAT Gateways in each AZ (for high availability)
resource "aws_nat_gateway" "main" {
  count         = length(var.availability_zones)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = {
    Name        = "nat-gateway-${var.availability_zones[count.index]}"
    Environment = "production"
    ManagedBy   = "terraform"
  }
  
  depends_on = [aws_internet_gateway.main]
}

# Route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = {
    Name        = "public-route-table"
    Environment = "production"
    Tier        = "public"
    ManagedBy   = "terraform"
  }
}

# Route tables for private application subnets (one per AZ)
resource "aws_route_table" "private_app" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }
  
  tags = {
    Name        = "private-app-route-table-${var.availability_zones[count.index]}"
    Environment = "production"
    Tier        = "private-app"
    ManagedBy   = "terraform"
  }
}

# Route tables for database subnets (one per AZ)
resource "aws_route_table" "private_db" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.main.id
  
  # No default route to internet - database instances should not have internet access
  
  tags = {
    Name        = "private-db-route-table-${var.availability_zones[count.index]}"
    Environment = "production"
    Tier        = "private-db"
    ManagedBy   = "terraform"
  }
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Associate private app subnets with private app route tables
resource "aws_route_table_association" "private_app" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private_app[count.index].id
}

# Associate database subnets with database route tables
resource "aws_route_table_association" "private_db" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private_db[count.index].id
}

# Network ACL for public subnets
resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.public[*].id
  
  # Allow inbound HTTP
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }
  
  # Allow inbound HTTPS
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }
  
  # Allow inbound ephemeral ports
  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }
  
  # Allow all outbound traffic
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  
  tags = {
    Name        = "public-nacl"
    Environment = "production"
    Tier        = "public"
    ManagedBy   = "terraform"
  }
}

# Network ACL for private application subnets
resource "aws_network_acl" "private_app" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.private_app[*].id
  
  # Allow inbound from public tier
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = aws_vpc.main.cidr_block
    from_port  = 0
    to_port    = 65535
  }
  
  # Allow inbound ephemeral ports from internet (for return traffic)
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }
  
  # Allow all outbound traffic within VPC
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = aws_vpc.main.cidr_block
    from_port  = 0
    to_port    = 0
  }
  
  # Allow outbound to internet
  egress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 65535
  }
  
  tags = {
    Name        = "private-app-nacl"
    Environment = "production"
    Tier        = "private-app"
    ManagedBy   = "terraform"
  }
}

# Network ACL for database subnets (most restrictive)
resource "aws_network_acl" "private_db" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.private_db[*].id
  
  # Allow inbound MySQL/Aurora from application tier
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, 0)
    from_port  = 3306
    to_port    = 3306
  }
  
  # Allow outbound return traffic to application tier
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, 0)
    from_port  = 1024
    to_port    = 65535
  }
  
  tags = {
    Name        = "private-db-nacl"
    Environment = "production"
    Tier        = "private-db"
    ManagedBy   = "terraform"
  }
}

# Security Group for web tier
resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Security group for web tier"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "HTTP from internet (for redirect to HTTPS)"
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
    description = "Allow all outbound traffic"
  }
  
  tags = {
    Name        = "web-security-group"
    Environment = "production"
    Tier        = "web"
    ManagedBy   = "terraform"
  }
}

# Security Group for application tier
resource "aws_security_group" "app" {
  name        = "app-sg"
  description = "Security group for application tier"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    description     = "Traffic from web tier"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  
  tags = {
    Name        = "app-security-group"
    Environment = "production"
    Tier        = "app"
    ManagedBy   = "terraform"
  }
}

# Security Group for database tier
resource "aws_security_group" "db" {
  name        = "db-sg"
  description = "Security group for database tier"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    description     = "MySQL/Aurora from application tier"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }
  
  # No egress rules - databases should not initiate outbound connections
  
  tags = {
    Name        = "db-security-group"
    Environment = "production"
    Tier        = "db"
    ManagedBy   = "terraform"
  }
}

# VPC Flow Logs
resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.vpc_flow_log.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
  
  tags = {
    Name        = "vpc-flow-logs"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# CloudWatch Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  name              = "/aws/vpc-flow-log/${aws_vpc.main.id}"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.log_key.arn
  
  tags = {
    Name        = "vpc-flow-log-group"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  
  route_table_ids = concat(
    [aws_route_table.public.id],
    aws_route_table.private_app[*].id,
  )
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = ["s3:GetObject", "s3:ListBucket"]
        Effect    = "Allow"
        Resource  = "*"
        Principal = "*"
      }
    ]
  })
  
  tags = {
    Name        = "s3-endpoint"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# DynamoDB Gateway Endpoint
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  
  route_table_ids = concat(
    [aws_route_table.public.id],
    aws_route_table.private_app[*].id,
  )
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:Query"]
        Effect    = "Allow"
        Resource  = "*"
        Principal = "*"
      }
    ]
  })
  
  tags = {
    Name        = "dynamodb-endpoint"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

Code Example for Bastion Host and VPN Connection:
```terraform
# Bastion Host Security Group
resource "aws_security_group" "bastion" {
  name        = "bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    description = "SSH from trusted IPs only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.trusted_ip_ranges # Not 0.0.0.0/0
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  
  tags = {
    Name        = "bastion-sg"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# Bastion Host Instance
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.bastion.id]
  key_name               = aws_key_pair.bastion.key_name
  
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2
    http_put_response_hop_limit = 1
  }
  
  tags = {
    Name        = "bastion-host"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# Elastic IP for Bastion
resource "aws_eip" "bastion" {
  domain = "vpc"
  
  tags = {
    Name        = "bastion-eip"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# EIP Association
resource "aws_eip_association" "bastion" {
  instance_id   = aws_instance.bastion.id
  allocation_id = aws_eip.bastion.id
}

# Virtual Private Gateway
resource "aws_vpn_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name        = "main-vpn-gateway"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# Customer Gateway (on-premise router)
resource "aws_customer_gateway" "main" {
  bgp_asn    = 65000
  ip_address = var.on_premise_router_ip
  type       = "ipsec.1"
  
  tags = {
    Name        = "main-customer-gateway"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# VPN Connection (with two tunnels for HA)
resource "aws_vpn_connection" "main" {
  vpn_gateway_id      = aws_vpn_gateway.main.id
  customer_gateway_id = aws_customer_gateway.main.id
  type                = "ipsec.1"
  static_routes_only  = true
  
  tags = {
    Name        = "main-vpn-connection"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# VPN Static Route
resource "aws_vpn_connection_route" "on_premise" {
  destination_cidr_block = var.on_premise_cidr
  vpn_connection_id      = aws_vpn_connection.main.id
}

# Add route to on-premise network in private route tables
resource "aws_route" "to_on_premise" {
  count                  = length(var.availability_zones)
  route_table_id         = aws_route_table.private_app[count.index].id
  destination_cidr_block = var.on_premise_cidr
  gateway_id             = aws_vpn_gateway.main.id
}
```