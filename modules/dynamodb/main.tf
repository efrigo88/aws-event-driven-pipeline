resource "aws_dynamodb_table" "this" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"

  global_secondary_index {
    name            = "status-index"
    hash_key        = "status"
    projection_type = "ALL"
  }
}

output "table_name" {
  value = aws_dynamodb_table.this.name
}

output "stream_arn" {
  value = aws_dynamodb_table.this.stream_arn
}
