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
  source = "./modules/ec2"
}

module "s3" {
  source       = "./modules/s3"
  project_name = var.project_name
}

module "lambda" {
  source                    = "./modules/lambda"
  sqs_queue_arn             = module.sqs.queue_arn
  sqs_queue_url             = module.sqs.queue_url
  ec2_ami_id                = module.ec2.ec2_ami_id
  ec2_instance_type         = var.worker_instance_type
  ec2_autoterminate_minutes = var.worker_autoterminate_minutes
  ec2_subnet_id             = module.vpc.subnet_id
  ec2_security_group_id     = module.vpc.security_group_id
  dynamodb_table_name       = module.dynamodb.table_name
  s3_bucket_name            = module.s3.bucket_name
}

module "eventbridge_lambda" {
  source               = "./modules/eventbridge_lambda"
  lambda_function_name = module.lambda.lambda_function_name
  lambda_function_arn  = module.lambda.lambda_function_arn
}
