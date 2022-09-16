terraform {
  backend "s3" {
    bucket = "AWS_BUCKET_NAME"
    key    = "AWS_BUCKET_KEY_NAME"
    region = "AWS_REGION"
    #dynamodb_table = "DYNAMODB_TABLE"
  }
}
