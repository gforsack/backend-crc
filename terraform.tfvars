# variable "rootdomain" {
# }

# variable "subdomain" {
# }

rootdomain = "itsgandhi.com"
subdomain = "www.itsgandhi.com"
dynamodb_table = "visitorCountDB"
lambda_name = "lambda-terraform"
apigw_name = "invokeLambdaAPI-terraform"
stage_name = "prod"

# variable "dynamodb_table" {
#   description = "Name of the DynamoDB table"
#   type        = string
#   default     = "visitorCountDB"

# }

# variable "lambda_name" {
#   description = "Name of the lambda function"
#   type        = string
#   default     = "lambda-terraform"

# }

# variable "apigw_name" {
#   description = "Name of REST API Gateway Resource"
#   type        = string
#   default     = "invokeLambdaAPI-terraform"

# }

# variable "stage_name" {
#   description = "Deployment stage"
#   type        = string
#   default     = "prod"
# }

# variable "zone_ID" {
# }
