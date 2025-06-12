resource "aws_iam_role" "pipe_role" {
  name = "eventbridge-pipe-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Effect" : "Allow",
      "Principal" : { "Service" : "pipes.amazonaws.com" },
      "Action" : "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "pipe_policy" {
  name = "eventbridge-pipe-policy"
  role = aws_iam_role.pipe_role.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:DescribeStream",
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator",
          "dynamodb:ListStreams"
        ],
        "Resource" : var.dynamodb_stream_arn
      },
      {
        "Effect" : "Allow",
        "Action" : ["sqs:SendMessage"],
        "Resource" : var.sqs_queue_arn
      }
    ]
  })
}
