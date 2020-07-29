provider "aws" {
  region = "eu-central-1"
}

terraform {
  backend "s3" {
    bucket = "terrafom-run-and-running-state-devopscoder331"
    key = "stage/data-stores/mysql/terraform.tfstate"
    region = "eu-central-1"

    dynamodb_table = "terraform-up-and-running-lock"
    encrypt = true
  }
}

resource "aws_db_instance" "example" {
  identifier_prefix = "terraform-up-and-running"
  engine = "mysql"
  allocated_storage = 10
  instance_class = "db.t2.micro"
  name = "example_database"
  username = "admin"

  password = var.db_password
}
