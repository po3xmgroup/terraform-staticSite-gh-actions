terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.26.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.0.1"
    }
  }
  required_version = ">= 1.1.0"

cloud {
    organization = "3xmgroup"

    workspaces {
      name = "po3xmgroup-staticsite"
    }
  }
}


provider "aws" {
  region = "us-east-1"
}
