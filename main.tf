### Create certiifcate in ACM for HTTPS traffic

resource "aws_acm_certificate" "acm-cert" {
  domain_name = "${var.domain_names.rootdomain}"
  subject_alternative_names = [
    "*.${var.domain_names.rootdomain}",
    "${var.domain_names.rootdomain}",
  ]
  validation_method = "DNS"
}

### SUBDOMAIN BUCKET CREATION WITH OAI POLICY
resource "aws_s3_bucket" "subdomain-bucket" {
  # (resource arguments)
  bucket = var.domain_names["subdomain"]

force_destroy = true
}

resource "aws_s3_bucket_policy" "cloudfront-oai-access" {
  bucket = aws_s3_bucket.subdomain-bucket.id
  policy = data.aws_iam_policy_document.allow_access_from_cloudfront.json
}

data "aws_iam_policy_document" "allow_access_from_cloudfront" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${aws_cloudfront_origin_access_identity.sub-oai.id}"]
    }
    actions = [
      "s3:GetObject",
    ]
    resources = [
      aws_s3_bucket.subdomain-bucket.arn,
      "${aws_s3_bucket.subdomain-bucket.arn}/*",
    ]
  }
  depends_on = [aws_s3_bucket.subdomain-bucket]
}

resource "aws_s3_bucket_public_access_block" "subdomain-public-access" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.subdomain-bucket.bucket
  ignore_public_acls      = true
  restrict_public_buckets = true
}

### ROOTDOMAIN BUCKET CREATION WITH TRAFFIC REDIRECT TO SUBDOMAIN BUCKET
resource "aws_s3_bucket" "rootdomain-bucket" {
  bucket = var.domain_names["rootdomain"]
}

resource "aws_s3_bucket_public_access_block" "rootdomain-public-access" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.rootdomain-bucket.bucket
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_website_configuration" "root-redirect" {
  bucket = aws_s3_bucket.rootdomain-bucket.bucket

  # redirect all requests to subdomain from root domain
  redirect_all_requests_to {
    host_name = aws_s3_bucket.subdomain-bucket.bucket
    protocol  = "https"
  }
}

resource "aws_cloudfront_distribution" "subdomain-distribution" {
  # (resource arguments)
  origin {
    # do something about the next 2 lines
    domain_name = "${aws_s3_bucket.subdomain-bucket.bucket}.s3.${aws_s3_bucket.subdomain-bucket.region}.amazonaws.com"
    origin_id   = "${aws_s3_bucket.subdomain-bucket.bucket}.s3.${aws_s3_bucket.subdomain-bucket.region}.amazonaws.com"

    s3_origin_config {
      origin_access_identity = "origin-access-identity/cloudfront/${aws_cloudfront_origin_access_identity.sub-oai.id}"
    }
  }

  aliases = [
    "${var.domain_names["subdomain"]}",
  ]
  comment             = "subdomain distribution"
  default_root_object = "index.html"
  enabled             = true
  http_version        = "http2"
  is_ipv6_enabled     = true
  price_class         = "PriceClass_100"

  wait_for_deployment = false

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    compress    = true
    default_ttl = 0
    max_ttl     = 0
    min_ttl     = 0
    # do something about line below
    target_origin_id       = "${var.domain_names.subdomain}.s3.us-east-1.amazonaws.com"
    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      locations        = []
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = aws_acm_certificate.acm-cert.arn
    cloudfront_default_certificate = false
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
  }

}

resource "aws_cloudfront_origin_access_identity" "sub-oai" {
  comment = "access-identity-${var.domain_names.subdomain}.s3.us-east-1.amazonaws.com"
}

### ROOT DOMAIN CF DISTRIBUTION
resource "aws_cloudfront_distribution" "rootdomain-distribution" {
  # (resource arguments)
  origin {
    ### do something about the next 2 lines
    domain_name = aws_s3_bucket_website_configuration.root-redirect.website_endpoint
    origin_id   = aws_s3_bucket_website_configuration.root-redirect.website_endpoint

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_keepalive_timeout = 5
      origin_protocol_policy   = "http-only"
      origin_read_timeout      = 30
      origin_ssl_protocols = [
        "TLSv1.2",
      ]
    }
  }
  aliases = [
    "${var.domain_names["rootdomain"]}",
  ]
  comment             = "root distribution"
  enabled             = true
  http_version        = "http2"
  is_ipv6_enabled     = true
  price_class         = "PriceClass_100"
  wait_for_deployment = false

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    compress               = true
    default_ttl            = 0
    max_ttl                = 0
    min_ttl                = 0
    target_origin_id       = aws_s3_bucket_website_configuration.root-redirect.website_endpoint
    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      locations        = []
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = aws_acm_certificate.acm-cert.arn
    cloudfront_default_certificate = false
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
  }
  depends_on = [aws_s3_bucket.rootdomain-bucket, aws_s3_bucket_website_configuration.root-redirect]
}

# Create A records for cloudfront distributions in Route53
resource "aws_route53_record" "www" {
  name    = "${var.domain_names["subdomain"]}"
  type    = "A"
  zone_id = var.zone_ID

  alias {
    evaluate_target_health = false
    name                   = aws_cloudfront_distribution.subdomain-distribution.domain_name
    zone_id                = aws_cloudfront_distribution.subdomain-distribution.hosted_zone_id
  }

}

resource "aws_route53_record" "root" {
  name    = "${var.domain_names["rootdomain"]}"
  type    = "A"
  zone_id = var.zone_ID

  alias {
    evaluate_target_health = false
    name                   = aws_cloudfront_distribution.rootdomain-distribution.domain_name
    zone_id                = aws_cloudfront_distribution.rootdomain-distribution.hosted_zone_id
  }
}

# Create DynamoDB to store site visitor count
resource "aws_dynamodb_table" "visitorCountStore" {
  name           = var.dynamodb_table
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "site"

  attribute {
    name = "site"
    type = "S"
  }
}

# Initialize visitor count by setting current count to zero
resource "aws_dynamodb_table_item" "initiateCount" {
  table_name = aws_dynamodb_table.visitorCountStore.name
  hash_key   = aws_dynamodb_table.visitorCountStore.hash_key

  item = <<ITEM
{
  "site": {"S": "CRC"},
  "visitor_count": {"N": "0"}
}
ITEM
}


# Create lambda function to update table count and give it required permissions
resource "aws_iam_role" "lambda-iam-role" {
  name               = "lambda-iam"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_policy" {
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:UpdateItem",
            ],
            "Effect": "Allow",
            "Resource": "${aws_dynamodb_table.visitorCountStore.arn}"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
            ],
            "Resource": "*"
                }
            ]
            })
        }

resource "aws_iam_role_policy_attachment" "lambda_policy_att" {
  role       = "${aws_iam_role.lambda-iam-role.name}"
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_function" "visitCounter" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename         = "lambda.zip"
  function_name    = var.lambda_name
  role             = aws_iam_role.lambda-iam-role.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda-zip.output_base64sha256
  runtime          = "python3.9"
  depends_on = [
    aws_dynamodb_table.visitorCountStore
  ]
}

data "archive_file" "lambda-zip" {
  type = "zip"
  #source_file = "{path.module}/../../lambda/my-function/index.js"  #python file location
  source_dir = "${path.module}/lambda/"
  output_path = "lambda.zip"

}

### Create API Gateway resource to invoke backend lambda function
resource "aws_api_gateway_rest_api" "invokeLambdaAPI" {
  name = var.apigw_name
  description = "Invokes Lambda function to update visitor count in DynamoDB and return current value"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# Allow API Gateway to invoke lambda function
resource "aws_lambda_permission" "APIGWAccess" {
  statement_id = "AllowAPIGatewayToInvokeLambdaFunction"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitCounter.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.invokeLambdaAPI.execution_arn}/*/*/*"

  depends_on = [
    aws_lambda_function.visitCounter
  ]
}

# Creating an API resource 'count'
resource "aws_api_gateway_resource" "count" {
  rest_api_id = aws_api_gateway_rest_api.invokeLambdaAPI.id
  parent_id   = aws_api_gateway_rest_api.invokeLambdaAPI.root_resource_id
  path_part   = "count"
}

// GET method
resource "aws_api_gateway_method" "get" {
  rest_api_id   = aws_api_gateway_rest_api.invokeLambdaAPI.id
  resource_id   = aws_api_gateway_resource.count.id
  http_method   = "GET"
  authorization = "NONE"
}

// Integrate API with Lambda fucncion visitCounter
resource "aws_api_gateway_integration" "integration-get" {
  rest_api_id             = aws_api_gateway_rest_api.invokeLambdaAPI.id
  resource_id             = aws_api_gateway_resource.count.id
  http_method             = aws_api_gateway_method.get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.visitCounter.invoke_arn}"
}

// Deploy API
resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.invokeLambdaAPI.id

  depends_on = [
    aws_api_gateway_integration.integration-get
  ]
  lifecycle {
    create_before_destroy = true
  }
}

// Stage name of deployment
resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.invokeLambdaAPI.id
  stage_name    = var.stage_name

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api-logs.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
  depends_on = [aws_cloudwatch_log_group.api-logs]
}

resource "aws_cloudwatch_log_group" "api-logs" {
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.invokeLambdaAPI.id}/${var.stage_name}"
  retention_in_days = 7
}
