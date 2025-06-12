resource "aws_eventbridge_pipe" "this" {
  name     = var.pipe_name
  role_arn = aws_iam_role.pipe_role.arn

  source = var.dynamodb_stream_arn
  source_parameters {
    dynamodb_stream_parameters {
      starting_position = "LATEST"
    }
  }

  target = var.sqs_queue_arn
  target_parameters {
    sqs_queue_parameters {}
  }

  filter_criteria {
    filter {
      pattern = jsonencode({
        "dynamodb" : {
          "NewImage" : {
            "status" : { "S" : ["PENDING"] }
          }
        }
      })
    }
  }
}

output "pipe_arn" {
  value = aws_eventbridge_pipe.this.arn
}
