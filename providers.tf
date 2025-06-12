terraform {
  required_version = "~> 1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "tram-case-playground"

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      Owner       = "mutt-data@tramcase.com"
      Team        = "Mutt Data"
      CostCenter  = "2025Q2-POC"
      ManagedBy   = "terraform"
    }
  }
}
