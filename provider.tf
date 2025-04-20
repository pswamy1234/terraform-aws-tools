terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.48.0"
    }
  }
  backend "s3" {
    bucket         = "swamy-jenkins"
    key            = "jenkins-test-1"
    region         = "us-east-1"
    dynamodb_table = "swamy-locking"
  }
}

#provide authentication here
provider "aws" {
  region = "us-east-1"
}