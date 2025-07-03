provider "aws" {
  region = var.aws_region
}
terraform {
  required_version = ">= 1.0"

   required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
 backend "s3" {
    bucket  = "my-terraform-statefilestore" 
    key     = "ec2/terraform.tfstate"           
    region  = "us-east-2"
    encrypt = true
  }
}
