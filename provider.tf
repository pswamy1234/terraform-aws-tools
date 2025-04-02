terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.48.0"
    }
  }
  backend "s3" {
    bucket         = "swamy-fun-remote-state-123456"
    key            = "jenkins-testing"
    region         = "us-east-1"
    dynamodb_table = "swamy.fun-locking"
  }
}

#provide authentication here
provider "aws" {
  region = "us-east-1"
}