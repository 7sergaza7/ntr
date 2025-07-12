
provider "aws" {
  region = "us-east-1"
}


resource "aws_s3_bucket" "site_bucket" {
  bucket = "website-content-s3"

  tags = {
    Name        = "Static Site Content Bucket"
    Environment = "Production"
  }
}

# versioning configuration for the S3 bucket
resource "aws_s3_bucket_versioning" "site_bucket_versioning" {
  bucket = aws_s3_bucket.site_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# move old versions to IA
resource "aws_s3_bucket_lifecycle_configuration" "site_bucket_lifecycle" {
  bucket = aws_s3_bucket.site_bucket.id

  rule {
    id     = "archive-noncurrent-versions"
    status = "Enabled"

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }
  }
}

resource "aws_s3_bucket" "log_bucket" {
  bucket = "website-content-s3-logs"

  tags = {
    Name        = "Static Site Log Bucket"
    Environment = "Production"
  }
}

# Block all public access to both buckets for security.
resource "aws_s3_bucket_public_access_block" "site_bucket_access" {
  bucket = aws_s3_bucket.site_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "log_bucket_access" {
  bucket = aws_s3_bucket.log_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable server access logging for the content bucket.
resource "aws_s3_bucket_logging" "site_bucket_logging" {
  bucket = aws_s3_bucket.site_bucket.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "s3-access-logs/"
}


# CloudFront access
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for my-static-site"
}

resource "aws_s3_bucket_policy" "site_bucket_policy" {
  bucket = aws_s3_bucket.site_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.oai.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.site_bucket.arn}/*"
      }
    ]
  })
}

# CloudFront distribution for the S3 bucket
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.site_bucket.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.site_bucket.id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for my static site"
  default_root_object = "index.html"


  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.log_bucket.bucket_domain_name
    prefix          = "cloudfront-access-logs/"
  }


  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.site_bucket.id}"

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
    cloudfront_default_certificate = true
  }

  tags = {
    Name        = "Static Site CloudFront"
    Environment = "Production"
  }
}


output "s3_content_bucket_name" {
  description = "The name of the S3 bucket for website content."
  value       = aws_s3_bucket.site_bucket.id
}

output "cloudfront_domain_name" {
  description = "The domain name of the CloudFront distribution."
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
}
