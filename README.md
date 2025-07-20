# Mars API Deployment Guide

## Architecture
```
GitHub → GitHub Actions → AWS ECR → EC2 (Docker) → RDS PostgreSQL
```

## Setup Steps

### 1. Terraform Infrastructure
```bash
cd terraform
terraform init
terraform plan -var="db_password=your_secure_password" -var="gemini_api_key=your_gemini_key"
terraform apply
```

### 2. GitHub Secrets
Add these secrets to your GitHub repository:
- `AWS_ACCESS_KEY_ID` - AWS access key
- `AWS_SECRET_ACCESS_KEY` - AWS secret key  
- `EC2_HOST` - EC2 public IP (from terraform output)
- `EC2_PRIVATE_KEY` - EC2 private key for SSH

### 3. SSM Parameters
Terraform creates these automatically:
- `/mars-api/database-url` - Complete PostgreSQL connection string
- `/mars-api/db-host` - RDS endpoint

You need to create manually:
- `/mars-api/gemini-api-key` - Your Gemini API key

### 4. Deploy
Push to main branch → GitHub Actions deploys automatically

## Local Development
```bash
# Start PostgreSQL
docker-compose up postgres -d

# Run API locally
uvicorn main:app --reload
```

## Cost Optimization
- EC2: t3.micro (free tier)
- RDS: db.t3.micro (free tier) 
- ECR: 500MB free per month
- Data transfer within same AZ is free

## Database Connection
- **Local**: Direct PostgreSQL connection
- **Production**: RDS endpoint from SSM Parameter Store
- **Security**: DB password in SSM, only EC2 can access RDS
# mars_api
