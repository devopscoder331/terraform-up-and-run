provider "aws" {
  region = "eu-central-1"
}

terraform {
  backend "s3" {
    bucket = "terrafom-run-and-running-state-devopscoder331"
    key = "prod/data-stores/mysql/terraform.tfstate"
    region = "eu-central-1"

    dynamodb_table = "terraform-up-and-running-lock"
    encrypt = true
  }
}

locals {
  db_creds = jsondecode(
    data.aws_secretsmanager_secret_version.db_password.secret_string
  )
}


resource "aws_db_instance" "example" {
  identifier_prefix = "terraform-prod"
  engine = "mysql"
  allocated_storage = 10
  instance_class = "db.t2.micro"
  name = "prod_database"
  skip_final_snapshot = true
  username = "admin"

  password = local.db_creds.password

}

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "prod"
}
