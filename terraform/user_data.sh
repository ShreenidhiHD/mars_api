#!/bin/bash
yum update -y
yum install -y docker

# Start Docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Login to ECR
aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin ${ecr_repo_uri}

# Create deployment script
cat > /home/ec2-user/deploy.sh << 'EOF'
#!/bin/bash
# Get latest image
aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin ${ecr_repo_uri}

# Stop existing container
docker stop mars-api || true
docker rm mars-api || true

# Pull and run latest image
docker pull ${ecr_repo_uri}:latest

# Get database URL from SSM
DATABASE_URL=$(aws ssm get-parameter --name "/mars-api/database-url" --with-decryption --query "Parameter.Value" --output text --region ${aws_region})
GEMINI_API_KEY=$(aws ssm get-parameter --name "/mars-api/gemini-api-key" --with-decryption --query "Parameter.Value" --output text --region ${aws_region})

# Run container with migrations
docker run -d \
  --name mars-api \
  -p 8000:8000 \
  -e DATABASE_URL="$DATABASE_URL" \
  -e GEMINI_API_KEY="$GEMINI_API_KEY" \
  -e ENVIRONMENT=production \
  ${ecr_repo_uri}:latest
EOF

chmod +x /home/ec2-user/deploy.sh
chown ec2-user:ec2-user /home/ec2-user/deploy.sh
