resource "aws_apigatewayv2_api" "api_gateway" {
  name          = "${local.name}-api"
  protocol_type = "HTTP"
}

