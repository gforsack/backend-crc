output "apigw_url" {
  value = aws_api_gateway_deployment.deployment.invoke_url
}

output "cloudfront_distribution_ID" {
  value = aws_cloudfront_distribution.subdomain-distribution.id
}
