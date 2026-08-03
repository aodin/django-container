terraform {
  # 1.10 is the floor for the S3 backend's native `use_lockfile` locking.
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Remote state. Set `state_bucket_name` in terraform.tfvars, create the bucket
  # with `tofu apply -target=aws_s3_bucket.state`, then uncomment this and run
  # `tofu init -migrate-state`. See the README's "Remote state" section.
  #
  # No DynamoDB table: `use_lockfile` uses S3 conditional writes for locking,
  # which needs OpenTofu >= 1.10.
  #
  # backend "s3" {
  #   bucket       = "django-container"
  #   key          = "django-container/production.tfstate"
  #   region       = "us-east-1"
  #   encrypt      = true
  #   use_lockfile = true
  # }
}

provider "aws" {
  region = var.aws_region

  # Empty falls back to the default credential chain, which is what CI uses
  # when it assumes the deploy role via OIDC.
  profile = var.aws_profile != "" ? var.aws_profile : null

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "opentofu"
    }
  }
}
