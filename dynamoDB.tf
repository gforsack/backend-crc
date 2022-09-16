# ON DEMAND DYNAMODB TABLE TO STORE VISITOR COUNT

resource "aws_dynamodb_table" "visitCount" {
  name           = "visitCount"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "site"
  range_key      = "visitorNumber"

  attribute {
    name = "site"
    type = "S"
  }

  attribute {
    name = "visitorNumber"
    type = "N"
  }

  ttl {
    attribute_name = "TimeToExist"
    enabled        = false
  }

  tags = {
    Environment = "production"
  }
}
