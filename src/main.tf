terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "terraform-state-087537145619-bucket"
    key    = "api-gateway-test.tfstate"
    region = "ap-northeast-1"
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-northeast-1"
  default_tags {
    tags = {
      env = "dev-terraform"
    }
  }
}


################################
# LambdaにアタッチするIAM Role
################################

resource "aws_iam_role" "lambda_role" {
  name = "lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}


################################
# Lambda
################################

# apiディレクトリにLambdaのソースコードがある前提
# apiディレクトリを api.zip という名前に固めて resource "aws_lambda_function" "api" から参照できるようにする
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "./api"
  output_path = "api.zip"
}

resource "aws_lambda_function" "api" {
  depends_on       = [aws_iam_role.lambda_role]
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "api"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.lambda_handler"
  runtime          = "nodejs20.x"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}


################################
# API GatewayにアタッチするIAM Role
################################

resource "aws_iam_role" "api_gateway_role" {
  name = "apigateway-role"
  assume_role_policy = data.aws_iam_policy_document.api_gateway_assume_role.json
}

resource "aws_iam_role_policy_attachment" "api_gateway_policy_logs" {
  role = aws_iam_role.api_gateway_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_iam_role_policy_attachment" "api_gateway_policy_lambda" {
  role = aws_iam_role.api_gateway_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaRole"
}

data "aws_iam_policy_document" "api_gateway_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}


################################
# API Gateway
################################

resource "aws_api_gateway_rest_api" "api" {
  name = "api-test-terraform"

  body = jsonencode({
    openapi = "3.0.1"
    info = {
      title   = "api"
      version = "1.0"
    }
    paths = {
      "/path1" = {
        get = {
          x-amazon-apigateway-integration = {
            httpMethod           = "POST"  # LambdaへのアクセスはPOSTでないといけないらしい
            payloadFormatVersion = "1.0"
            type                 = "AWS_PROXY"
            uri                  = aws_lambda_function.api.invoke_arn
            credentials          = aws_iam_role.api_gateway_role.arn
          }
        }
      }
    }
  })
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  depends_on  = [aws_api_gateway_rest_api.api]
  stage_name  = "prod"
  triggers = {
    # resource "aws_lambda_function" "api" の内容が変わるごとにデプロイされるようにする
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.api))
  }
}

data "aws_iam_policy_document" "api_gateway_policy" {
  statement {
    effect = "Allow"
    principals {
      type = "*"
      identifiers = ["*"]
    }
    actions   = ["execute-api:Invoke"]
    resources = ["${aws_api_gateway_rest_api.api.execution_arn}/*"]
  }
}

resource "aws_api_gateway_rest_api_policy" "policy" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  policy = data.aws_iam_policy_document.api_gateway_policy.json
}