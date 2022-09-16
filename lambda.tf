
resource "aws_lambda_function" "visitCounter" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "arn:aws:s3:::lambda-code-bucket32102/ddb_table_update.zip"
  function_name = "lambda-terraform"
  role          = LAMBDA_ROLE
  handler       = "lambda-terraform.lambda_handler"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  # source_code_hash = filebase64sha256("lambda_function_payload.zip")

  runtime = "python3.9"

  tags = {
    Environment = "production"
  }
 
}
