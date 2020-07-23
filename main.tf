provider "aws" {
  region = "eu-central-1"
}

resource "aws_instance" "example" {
  ami = "ami-0d359437d1756caa8"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance2.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF
  tags = {
    Name = "terraform-example-web"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "instance2" {
    name = "terrafom-example-group2"

    ingress {
      from_port = var.server_port
      to_port = var.server_port
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
}

variable "server_port" {
  description = "The port the server will use for http request"
  type = number
  default = 8080
}
