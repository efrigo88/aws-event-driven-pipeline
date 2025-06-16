locals {
  bucket_name = "mutt-data-${var.project_name}-pipeline-fhslxnfjksns"
}

data "archive_file" "worker_script" {
  type        = "zip"
  source_file = "${path.root}/scripts/sqs_worker.py"
  output_path = "${path.root}/scripts/sqs_worker.zip"
}

resource "aws_s3_bucket" "this" {
  bucket        = local.bucket_name
  force_destroy = true
}

# Block public access
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "sqs_worker" {
  bucket       = aws_s3_bucket.this.id
  key          = "sqs_worker.py"
  source       = "${path.root}/scripts/sqs_worker.py"
  etag         = data.archive_file.worker_script.output_md5
  content_type = "text/x-python"
}

# Upload data input directory
resource "aws_s3_object" "data_files" {
  bucket   = aws_s3_bucket.this.id
  for_each = fileset("${path.module}/../../data/input", "**/*")
  key      = "data/input/${each.value}"
  source   = "${path.module}/../../data/input/${each.value}"
  etag     = filemd5("${path.module}/../../data/input/${each.value}")
}

output "bucket_name" {
  value = aws_s3_bucket.this.bucket
}
