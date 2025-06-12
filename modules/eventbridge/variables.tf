variable "pipe_name" {
  description = "Name of the EventBridge pipe."
  type        = string
  default     = "dynamodb-to-sqs-pipe"
}

variable "dynamodb_stream_arn" {
  description = "ARN of the DynamoDB stream."
  type        = string
}

variable "sqs_queue_arn" {
  description = "ARN of the SQS queue."
  type        = string
}
