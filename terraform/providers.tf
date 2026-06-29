terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket         = "pyforum-terraform-state-891376973099"
    key            = "pyforum/terraform.tfstate"
    region         = "eu-central-1"
    profile        = "pyforum"
    dynamodb_table = "pyforum-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project   = "pyforum"
      ManagedBy = "terraform"
    }
  }
}

provider "http" {}
provider "tls" {}
provider "local" {}
provider "random" {}
