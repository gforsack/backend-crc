resource "aws_dynamodb_table" "visitorCountStore" {
  name           = "visitCountDB"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "site"

  attribute {
    name = "site"
    type = "S"
  }

#    attribute {
#     name = "numVisitors"
#     type = "N"
#   }

  ttl {
    attribute_name = "TimeToExist"
    enabled        = false
  }

  tags = {
    Environment = "production"
  }
}
