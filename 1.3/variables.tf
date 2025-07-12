variable "region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-east-1"

}

variable "bucket_name" {
  description = "The name of the S3 bucket for static site hosting."
  type        = string
  default     = "my-static-site-bucket"

}
