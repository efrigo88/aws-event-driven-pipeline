resource "aws_sqs_queue" "this" {
  name = var.sqs_queue_name
}

output "queue_url" {
  value = aws_sqs_queue.this.url
}

output "queue_arn" {
  value = aws_sqs_queue.this.arn
}
