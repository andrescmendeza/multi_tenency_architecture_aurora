terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.60.0"
    }
  }
  required_version = ">= 1.0.2"
  cloud {
    organization = "eLuma"
    workspaces {
      name = "Feature"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

