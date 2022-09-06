
resource "aws_lambda_function" "lambda_function" {
  function_name = "${local.name}-lambda"
  role          = aws_iam_role.lambda_role.arn

  runtime = "go1.x"
  handler = "main"

  filename         = "dist/lambda.zip"
  source_code_hash = filebase64sha256("dist/lambda.zip")
  environment {
    variables = {
      SENTRY_DSN = var.sentry_dsn
      RELEASE    = substr(filebase64sha256("dist/lambda.zip"), 0, 5)
    }
  }
}


resource "aws_cloudwatch_log_group" "lambda_function_log_group" {
  name = "/aws/lambda/${aws_lambda_function.lambda_function.function_name}"

  retention_in_days = 7
}


resource "aws_iam_role" "lambda_role" {
  name = "${local.name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}