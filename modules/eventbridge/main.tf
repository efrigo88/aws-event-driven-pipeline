resource "aws_cloudformation_stack" "pipe" {
  name          = var.pipe_name
  template_body = file("${path.module}/pipe.yaml")
  capabilities  = ["CAPABILITY_NAMED_IAM"]

  parameters = {
    PipeName          = var.pipe_name
    PipeRoleArn       = aws_iam_role.pipe_role.arn
    DynamoDBStreamArn = var.dynamodb_stream_arn
    SQSQueueArn       = var.sqs_queue_arn
  }
}

output "pipe_arn" {
  value = aws_cloudformation_stack.pipe.outputs["PipeArn"]
}
