locals {
  bucket_name = "mutt-data-${var.project_name}-pipeline-logs-fhslxnfjksns"
}

resource "aws_s3_bucket" "logs" {
  bucket        = local.bucket_name
  force_destroy = true
}

# Block public access
resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "bucket_name" {
  value = aws_s3_bucket.logs.bucket
}
