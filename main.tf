provider "aws" {
  region = "eu-central-1"
}

resource "aws_launch_configuration" "example" {
  image_id = "ami-0d359437d1756caa8"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.instance2.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier = data.aws_subnet_ids.default.ids

  min_size = 2
  max_size = 10

  tag {
    key = "name"
    value = "terraform-asg-example"
    propagate_at_launch = true
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

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}
