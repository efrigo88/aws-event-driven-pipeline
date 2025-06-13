data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.root}/modules/lambda/build"
  output_path = "${path.root}/modules/lambda/build/lambda_function.zip"
}

resource "aws_lambda_function" "rag_launcher" {
  function_name    = "rag-launcher"
  description      = "Lambda function to launch EC2 instances for RAG workers"
  architectures    = ["x86_64"]
  filename         = data.archive_file.lambda_zip.output_path
  role             = aws_iam_role.lambda_exec.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  environment {
    variables = {
      SQS_QUEUE_URL             = var.sqs_queue_url
      DYNAMODB_TABLE_NAME       = var.dynamodb_table_name
      EC2_TAG_KEY               = "Role"
      EC2_TAG_VALUE             = "rag-worker"
      EC2_AMI_ID                = var.ec2_ami_id
      EC2_INSTANCE_TYPE         = var.ec2_instance_type
      EC2_AUTOTERMINATE_MINUTES = var.ec2_autoterminate_minutes
      EC2_SUBNET_ID             = var.ec2_subnet_id
      EC2_SECURITY_GROUP_ID     = var.ec2_security_group_id
      S3_BUCKET_NAME            = var.s3_bucket_name
      EC2_KEY_NAME              = var.ec2_key_name
      EC2_INSTANCE_PROFILE_NAME = var.ec2_instance_profile_name
    }
  }
  depends_on = [aws_cloudwatch_log_group.lambda_log_group]
}

output "lambda_function_name" {
  value = aws_lambda_function.rag_launcher.function_name
}

output "lambda_function_arn" {
  value = aws_lambda_function.rag_launcher.arn
}
