resource "aws_dynamodb_table" "table" {
  name           = var.table_name
  read_capacity  = "20"
  write_capacity = "20"
  hash_key       = "ID"

  point_in_time_recovery {
    enabled = var.point_in_time_recovery
  }

  attribute {
    name = "ID"
    type = "S"
  }
}
