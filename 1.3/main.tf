module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "my-s3-bucket"
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  versioning = {
    enabled = true
  }
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name        = "MyS3Bucket"
    Environment = "Production"
  }
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  lifecycle_rule = [
    {
      id      = "move-old-versions-to-ia"
      enabled = true
      noncurrent_version_transition = [{
        days          = 30            # ⏳ After 30 days
        storage_class = "STANDARD_IA" # 📦 Move to Infrequent Access
      }]
    }
  ]
  logging = {
    target_bucket = "my-log-bucket"
    target_prefix = "s3-access-logs/"
  }
}
