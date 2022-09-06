output "function_name" {
  description = "Name of the Lambda function."
  value       = aws_lambda_function.lambda_function.function_name
}

output "base_url" {
  description = "Base URL for API Gateway stage."
  value       = aws_api_gateway_deployment.apigw_deploy.invoke_url
}