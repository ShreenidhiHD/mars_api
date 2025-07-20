output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.mars_api.repository_url
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.mars_api.endpoint
}

output "ec2_public_ip" {
  description = "EC2 instance public IP"
  value       = aws_instance.mars_api.public_ip
}

output "database_url_ssm_parameter" {
  description = "SSM parameter name for database URL"
  value       = aws_ssm_parameter.db_url.name
}

output "frontend_s3_bucket" {
  description = "S3 bucket for frontend hosting"
  value       = aws_s3_bucket.frontend_hosting.bucket
}

output "cdn_s3_bucket" {
  description = "S3 bucket for CDN assets"
  value       = aws_s3_bucket.cdn_assets.bucket
}

output "cloudfront_url" {
  description = "CloudFront distribution URL"
  value       = aws_cloudfront_distribution.frontend.domain_name
}

output "domain_nameservers" {
  description = "Route53 nameservers for domain configuration"
  value       = aws_route53_zone.main.name_servers
}
