resource "aws_sqs_queue" "this" {
  name                       = var.sqs_queue_name
  visibility_timeout_seconds = 3600
}

output "queue_url" {
  value = aws_sqs_queue.this.url
}

output "queue_arn" {
  value = aws_sqs_queue.this.arn
}
