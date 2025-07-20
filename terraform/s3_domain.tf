# S3 Buckets for Frontend
resource "aws_s3_bucket" "frontend_hosting" {
  bucket = "${var.domain_name}-frontend"
  
  tags = {
    Name        = "Mars UI Frontend Hosting"
    Environment = "production"
  }
}

resource "aws_s3_bucket" "cdn_assets" {
  bucket = "${var.domain_name}-cdn"
  
  tags = {
    Name        = "Mars UI CDN Assets"
    Environment = "production"
  }
}

# S3 Website Configuration
resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend_hosting.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# S3 Public Access for Frontend
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend_hosting.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend_hosting.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = "s3:GetObject"
        Resource = "${aws_s3_bucket.frontend_hosting.arn}/*"
      }
    ]
  })
}

# CloudFront Distribution for CDN
resource "aws_cloudfront_distribution" "frontend" {
  origin {
    domain_name = aws_s3_bucket.frontend_hosting.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.frontend_hosting.id}"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = [var.domain_name, "www.${var.domain_name}"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.frontend_hosting.id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.main.arn
    ssl_support_method  = "sni-only"
  }

  tags = {
    Name = "Mars UI CloudFront"
  }
}

# Route53 Domain
resource "aws_route53_zone" "main" {
  name = var.domain_name

  tags = {
    Name = "Mars API Domain"
  }
}

# SSL Certificate
resource "aws_acm_certificate" "main" {
  domain_name       = var.domain_name
  subject_alternative_names = ["www.${var.domain_name}", "api.${var.domain_name}"]
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "Mars API SSL Certificate"
  }
}

# Route53 Records
resource "aws_route53_record" "frontend" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.frontend.domain_name
    zone_id                = aws_cloudfront_distribution.frontend.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.mars_api.public_ip]
}
