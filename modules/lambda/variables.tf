variable "sqs_queue_arn" {
  description = "ARN of the SQS queue."
  type        = string
}

variable "sqs_queue_url" {
  description = "URL of the SQS queue."
  type        = string
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table."
  type        = string
}

variable "ec2_ami_id" {
  description = "AMI ID for the EC2 instance."
  type        = string
}

variable "ec2_instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "ec2_autoterminate_minutes" {
  description = "Minutes after which EC2 should auto-terminate."
  type        = number
  default     = 5
}

variable "ec2_subnet_id" {
  description = "Subnet ID for EC2 instance."
  type        = string
}

variable "ec2_security_group_id" {
  description = "Security group ID for EC2 instance."
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 bucket name for EC2 log uploads."
  type        = string
}

variable "ec2_key_name" {
  description = "EC2 key pair name for SSH access."
  type        = string
}

variable "ec2_instance_profile_name" {
  description = "EC2 instance profile name for IAM role attachment."
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming."
  type        = string
}
