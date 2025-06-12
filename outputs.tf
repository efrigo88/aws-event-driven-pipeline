output "dynamodb_table_name" {
  value = module.dynamodb.table_name
}

output "sqs_queue_url" {
  value = module.sqs.queue_url
}

output "eventbridge_pipe_arn" {
  value = module.eventbridge.pipe_arn
}
