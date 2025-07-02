variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "lambda_name" {
  description = "lambda name"
  type        = string
  default     = "calculator_lambda"
}
