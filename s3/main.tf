provider "aws" {
  region = "eu-central-1"
}

terraform {
  backend "s3" {
    bucket = "terrafom-run-and-running-state-devopscoder331"
    key = "global/s3/terraform.tfstate"
    region = "eu-central-1"

    dynamodb_table = "terraform-up-and-running-lock"
    encrypt = true
  }
}

resource "aws_s3_bucket" "terraform_state" {
    bucket = "terrafom-run-and-running-state-devopscoder331"

    lifecycle {
      prevent_destroy = true
    }

    versioning {
      enabled = true
    }

    server_side_encryption_configuration {
      rule {
        apply_server_side_encryption_by_default {
          sse_algorithm = "AES256"
        }
      }
    }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name = "terraform-up-and-running-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.terraform_state.arn
  description = "The ARN of the S3 bucket"
}

output "dynamodb_table_name" {
 value = aws_dynamodb_table.terraform_locks.name
  description = "The name of the DynamoDB table"
}
