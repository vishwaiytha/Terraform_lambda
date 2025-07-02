
resource "aws_s3_bucket" "lambda_deployments" {
  bucket = "${var.lambda_name}-lambda-deployments-${var.environment}"
}

# S3 Bucket for application data
resource "aws_s3_bucket" "app_data" {
  bucket = "${var.lambda_name}-app-data-${var.environment}"
}

# Create ZIP file from source code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "lambda/lambda.js"  # or wherever your source file is
  output_path = "lambda.zip"
}



# Lambda Function
resource "aws_lambda_function" "main_function" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.lambda_name}-function-${var.environment}"
  role             =  aws_iam_role.lambda_role.arn
  handler          = "lambda.handler"
  runtime          = "nodejs18.x"
  timeout          = 30
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.main_table.name
      S3_BUCKET  = aws_s3_bucket.app_data.bucket
    }
  }


  tags = {
    Name        = "${var.lambda_name}-function-${var.environment}"
    Environment = var.environment
  }
}

# DynamoDB Table
resource "aws_dynamodb_table" "main_table" {
  name           = "${var.lambda_name}-table-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S" 
  }

  tags = {
    Name        = "${var.lambda_name}-table-${var.environment}"
    Environment = var.environment
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.lambda_name}-lambda-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
        Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.lambda_name}-lambda-policy-${var.environment}"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.main_table.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.app_data.arn}/*",
          "${aws_s3_bucket.lambda_deployments.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.app_data.arn,
          aws_s3_bucket.lambda_deployments.arn
        ]
      }
    ]
  })
}
