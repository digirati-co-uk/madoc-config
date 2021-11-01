provider "aws" {
  region = var.region
}

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.63.0"
    }

    template = {
      source  = "hashicorp/template"
      version = "2.2.0"
    }
  }


  backend "s3" {
    bucket = "EXAMPLE_NAME-remote-state"
    key    = "terraform.tfstate"
    region = "eu-west-3"
  }
}