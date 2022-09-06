terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {

}

locals {
  name = "api-gw-lambda-echo-sentry"
}