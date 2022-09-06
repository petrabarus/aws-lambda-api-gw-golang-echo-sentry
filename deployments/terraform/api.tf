resource "aws_api_gateway_rest_api" "apigw" {
  name = "${local.name}-api"
}
resource "aws_iam_role" "apigw_cloudwatch_role" {
  name = "${local.name}-cloudwatch"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "apigateway.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_api_gateway_account" "apigw_account" {
  cloudwatch_role_arn = aws_iam_role.apigw_cloudwatch_role.arn
}

resource "aws_iam_role_policy" "apigw_cloudwatch_role_policy" {
  name = "${local.name}-cloudwatch-policy"
  role = aws_iam_role.apigw_cloudwatch_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

locals {
  apigw_stage_name = "dev"
}

resource "aws_api_gateway_deployment" "apigw_deploy" {
  depends_on = [
    aws_api_gateway_integration.apigw_lambda_integration,
    aws_api_gateway_integration.apigw_lambda_integration_root,
    aws_api_gateway_account.apigw_account,
  ]

  rest_api_id = aws_api_gateway_rest_api.apigw.id
  stage_name  = local.apigw_stage_name
}

resource "aws_api_gateway_method_settings" "apigw_logging" {
  depends_on = [
    aws_iam_role_policy.apigw_cloudwatch_role_policy,
    aws_api_gateway_deployment.apigw_deploy
  ]

  rest_api_id = aws_api_gateway_rest_api.apigw.id
  stage_name  = local.apigw_stage_name
  method_path = "*/*"

  settings {
    logging_level      = "INFO"
    data_trace_enabled = true
    metrics_enabled    = true
  }
}

resource "aws_cloudwatch_log_group" "apigw_loggroup" {
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.apigw.id}/${local.apigw_stage_name}"
  retention_in_days = 7
}

resource "aws_api_gateway_resource" "apigw_proxy" {
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  parent_id   = aws_api_gateway_rest_api.apigw.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "apigw_proxy_method" {
  rest_api_id   = aws_api_gateway_rest_api.apigw.id
  resource_id   = aws_api_gateway_resource.apigw_proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "apigw_lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  resource_id = aws_api_gateway_method.apigw_proxy_method.resource_id
  http_method = aws_api_gateway_method.apigw_proxy_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_function.invoke_arn
}

resource "aws_api_gateway_method" "apigw_proxy_root" {
  rest_api_id   = aws_api_gateway_rest_api.apigw.id
  resource_id   = aws_api_gateway_rest_api.apigw.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "apigw_lambda_integration_root" {
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  resource_id = aws_api_gateway_method.apigw_proxy_root.resource_id
  http_method = aws_api_gateway_method.apigw_proxy_root.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_function.invoke_arn
}

resource "aws_lambda_permission" "apigw_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.apigw.execution_arn}/*/*"
}
