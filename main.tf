provider "aws" {
  region = "eu-central-1"
}

resource "aws_instance" "example" {
  ami = "ami-0e8286b71b81c3cc1"
  instance_type = "t2.micro"

  tags = {
    Name = "terraform-example"
  }
}
