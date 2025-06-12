resource "aws_pipes_pipe" "this" {
  name     = var.pipe_name
  role_arn = aws_iam_role.pipe_role.arn
  source   = var.dynamodb_stream_arn
  target   = var.sqs_queue_arn

  source_parameters {
    dynamodb_stream_parameters {
      starting_position = "LATEST"
    }
    filter_criteria {
      filter {
        pattern = jsonencode({
          dynamodb = {
            NewImage = {
              status = { S = ["PENDING"] }
            }
          }
        })
      }
    }
  }

  target_parameters {
    sqs_queue_parameters {}
  }
}

output "pipe_arn" {
  value = aws_pipes_pipe.this.arn
}
