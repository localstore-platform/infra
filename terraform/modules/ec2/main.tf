# EC2 Module - Main Configuration

# Get latest Amazon Linux 2023 AMI (has AWS CLI pre-installed)
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IAM Role for EC2 to access ECR
resource "aws_iam_role" "ec2_ecr" {
  name = "localstore-${var.environment}-ec2-ecr-role"

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

  tags = {
    Name = "localstore-${var.environment}-ec2-ecr-role"
  }
}

# IAM Policy for ECR access
resource "aws_iam_role_policy" "ecr_access" {
  name = "localstore-${var.environment}-ecr-access"
  role = aws_iam_role.ec2_ecr.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_ecr" {
  name = "localstore-${var.environment}-ec2-ecr-profile"
  role = aws_iam_role.ec2_ecr.name
}

# Security Group for API
resource "aws_security_group" "api" {
  name        = "localstore-${var.environment}-api-sg"
  description = "Security group for LocalStore API"
  vpc_id      = var.vpc_id

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  # SSH - restricted to admin IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip]
    description = "SSH from admin"
  }

  # All outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound"
  }

  tags = {
    Name = "localstore-${var.environment}-api-sg"
  }
}

# EC2 Instance
resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.api.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_ecr.name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = <<-EOF
              #!/bin/bash
              # Amazon Linux 2023 already has AWS CLI installed
              
              # Install Docker
              dnf update -y
              dnf install -y docker
              systemctl start docker
              systemctl enable docker
              usermod -a -G docker ec2-user
              
              # Install Docker Compose V2 plugin
              mkdir -p /usr/local/lib/docker/cli-plugins
              curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/lib/docker/cli-plugins/docker-compose
              chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
              
              # Also install for ec2-user
              mkdir -p /home/ec2-user/.docker/cli-plugins
              cp /usr/local/lib/docker/cli-plugins/docker-compose /home/ec2-user/.docker/cli-plugins/
              chown -R ec2-user:ec2-user /home/ec2-user/.docker
              
              # Create app directory
              mkdir -p /opt/localstore
              chown ec2-user:ec2-user /opt/localstore
              
              # Pre-authenticate to ECR (will use instance profile)
              # Get AWS account ID and region dynamically (IMDSv2 requires token)
              TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
              AWS_REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)
              AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
              aws ecr get-login-password --region $AWS_REGION | \
                docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com || true
              EOF

  tags = {
    Name = "localstore-${var.environment}-app"
  }
}

# Elastic IP (optional - for consistent public IP)
resource "aws_eip" "app" {
  count    = var.create_eip ? 1 : 0
  instance = aws_instance.app.id
  domain   = "vpc"

  tags = {
    Name = "localstore-${var.environment}-eip"
  }
}
