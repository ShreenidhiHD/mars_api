# Terraform configuration for Mars API infrastructure
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# AWS Provider - Uses ~/.aws/credentials file with profile
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile  # Uses profile from ~/.aws/credentials
}

# ECR Repository for Docker images
resource "aws_ecr_repository" "mars_api" {
  name                 = "mars-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# RDS Subnet Group
resource "aws_db_subnet_group" "mars_api" {
  name       = "mars-api-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name = "Mars API DB subnet group"
  }
}

# RDS PostgreSQL Database - FREE TIER OPTIMIZED
resource "aws_db_instance" "mars_api" {
  identifier             = "mars-api-db"
  engine                 = "postgres"
  engine_version         = "15.4"
  instance_class         = "db.t3.micro"   
  allocated_storage      = 20               
  storage_type           = "gp2"          
  
  db_name  = "mars_api"
  username = "mars_user"
  password = var.db_password
  
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.mars_api.name
  
 
  multi_az               = false           
  backup_retention_period = 7              
  backup_window          = "03:00-04:00"  
  maintenance_window     = "sun:04:00-sun:05:00"
  
  skip_final_snapshot = true
  deletion_protection = false              
  
  tags = {
    Name        = "Mars API Database"
    Environment = "free-tier"
  }
}

# Store DB credentials in Systems Manager
resource "aws_ssm_parameter" "db_url" {
  name  = "/mars-api/database-url"
  type  = "SecureString"
  value = "postgresql://${aws_db_instance.mars_api.username}:${var.db_password}@${aws_db_instance.mars_api.endpoint}/${aws_db_instance.mars_api.db_name}"
}

resource "aws_ssm_parameter" "db_host" {
  name  = "/mars-api/db-host"
  type  = "String"
  value = aws_db_instance.mars_api.endpoint
}

# EC2 Instance for running Docker - FREE TIER OPTIMIZED
resource "aws_instance" "mars_api" {
  ami           = "ami-0c02fb55956c7d316" 
  instance_type = "t3.micro"              
  
  vpc_security_group_ids = [aws_security_group.ec2.id]
  subnet_id              = aws_subnet.public_a.id
  
  associate_public_ip_address = true    

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  
  # Root volume optimization for free tier
  root_block_device {
    volume_type = "gp2"                   
    volume_size = 8                  
    encrypted   = false                
  }
  
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    ecr_repo_uri = aws_ecr_repository.mars_api.repository_url
    aws_region   = var.aws_region
  }))
  
  tags = {
    Name        = "Mars API Server"
    Environment = "free-tier"
  }
}
