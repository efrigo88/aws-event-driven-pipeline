module "vpc" {
  source       = "./modules/vpc"
  project_name = var.project_name
}

module "dynamodb" {
  source = "./modules/dynamodb"
}

module "sqs" {
  source = "./modules/sqs"
}

module "eventbridge" {
  source              = "./modules/eventbridge"
  dynamodb_stream_arn = module.dynamodb.stream_arn
  sqs_queue_arn       = module.sqs.queue_arn
}

module "ec2" {
  source             = "./modules/ec2"
  project_name       = var.project_name
  dynamodb_table_arn = module.dynamodb.table_arn
  s3_bucket_name     = module.s3.bucket_name
  sqs_queue_arn      = module.sqs.queue_arn
}

module "s3" {
  source       = "./modules/s3"
  project_name = var.project_name
}

module "lambda" {
  source                    = "./modules/lambda"
  region                    = var.aws_region
  sqs_queue_arn             = module.sqs.queue_arn
  sqs_queue_url             = module.sqs.queue_url
  dynamodb_table            = module.dynamodb.table_name
  s3_bucket_name            = module.s3.bucket_name
  ec2_ami_id                = module.ec2.ec2_ami_id
  ec2_instance_type         = var.worker_instance_type
  ec2_autoterminate_minutes = var.worker_autoterminate_minutes
  ec2_subnet_id             = module.vpc.subnet_id
  ec2_security_group_id     = module.vpc.security_group_id
  ec2_key_name              = module.ec2.ec2_key_name
  ec2_instance_profile_name = module.ec2.ec2_instance_profile_name
  project_name              = var.project_name
}

module "eventbridge_lambda" {
  source               = "./modules/eventbridge_lambda"
  schedule_expression  = var.eventbridge_schedule_expression
  lambda_function_name = module.lambda.lambda_function_name
  lambda_function_arn  = module.lambda.lambda_function_arn
}
