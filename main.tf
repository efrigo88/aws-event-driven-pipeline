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
