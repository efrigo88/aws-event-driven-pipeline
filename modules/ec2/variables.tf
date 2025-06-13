variable "project_name" {
  description = "Project name for resource naming."
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table."
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 bucket name for log uploads."
  type        = string
}
