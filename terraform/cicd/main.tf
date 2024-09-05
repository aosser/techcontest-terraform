terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "terraform-state-087537145619-bucket"
    key    = "cicd-test.tfstate"
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