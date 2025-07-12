# -----------------------------------------------------------
# CloudFront Distribution for Static Content
# -----------------------------------------------------------

# Create an Origin Access Control (OAC) for secure S3 integration
resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "${module.s3_bucket.s3_bucket_id}-oac"
  description                       = "OAC for S3 bucket ${module.s3_bucket.s3_bucket_id}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always" # CloudFront will always sign requests to the S3 origin
  signing_protocol                  = "sigv4"  # Use Signature Version 4
}

# Define the CloudFront distribution
resource "aws_cloudfront_distribution" "s3_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for static site: ${module.s3_bucket.s3_bucket_id}"
  default_root_object = "index.html"

  origin {
    domain_name              = module.s3_bucket.s3_bucket_bucket_regional_domain_name # Use the regional S3 endpoint
    origin_id                = "S3-${module.s3_bucket.s3_bucket_id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id # Link to the OAC
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${module.s3_bucket.s3_bucket_id}"
    viewer_protocol_policy = "redirect-to-https" # Force HTTPS for viewers
    min_ttl                = 0
    default_ttl            = 86400    # Cache for 24 hours by default
    max_ttl                = 31536000 # Max cache for 1 year

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none" # No geographic restrictions
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true # Use CloudFront's default SSL certificate
  }
}

# -----------------------------------------------------------
# S3 Bucket Policy to Allow CloudFront Access
# -----------------------------------------------------------
resource "aws_s3_bucket_policy" "allow_cloudfront_access" {
  bucket = module.s3_bucket.s3_bucket_id # Attach policy to our S3 bucket

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com" # Allow CloudFront service
        }
        Action   = "s3:GetObject"                        # Grant permission to retrieve objects
        Resource = "${module.s3_bucket.s3_bucket_arn}/*" # Apply to all objects in the bucket
        Condition = {
          StringEquals = {
            # 🔒 Restrict access to only *this specific* CloudFront distribution
            "AWS:SourceArn" = aws_cloudfront_distribution.s3_distribution.arn
          }
        }
      }
    ]
  })
}

# -----------------------------------------------------------
# Outputs
# -----------------------------------------------------------
output "s3_bucket_name" {
  description = "The name of the S3 bucket configured for static site hosting."
  value       = module.s3_bucket.s3_bucket_id
}

output "cloudfront_domain_name" {
  description = "The domain name of the CloudFront distribution. Use this URL to access your static site."
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
}

output "cloudfront_console_url" {
  description = "Direct link to the CloudFront distribution in the AWS console."
  value       = "https://console.aws.amazon.com/cloudfront/home?region=${data.aws_region.current.name}#/distributions/${aws_cloudfront_distribution.s3_distribution.id}"
}

# Data source to get the current AWS region, useful for console URLs
data "aws_region" "current" {}
