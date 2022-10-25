variable "domain_names" {
  type = map(any)
  default = {
    "subdomain"  = "${{ secrets.SUBDOMAIN }}"
    "rootdomain" = "${{ secrets.ROOT_DOMAIN }}"
  }
}


variable "dynamodb_table" {
  description = "Name of the DynamoDB table"
  type        = string
  default     = "visitorCountDB"

}

variable "lambda_name" {
  description = "Name of the lambda function"
  type        = string
  default     = "lambda-terraform"

}

variable "apigw_name" {
  description = "Name of REST API Gateway Resource"
  type        = string
  default     = "invokeLambdaAPI-terraform"

}

variable "stage_name" {
  description = "Deployment stage"
  type        = string
  default     = "prod"
}

variable "zone_ID" {
  description = "Hosted zone ID in Route 53"
  type        = string
  default     = "${{ secrets.ZONE_ID }}"
}
