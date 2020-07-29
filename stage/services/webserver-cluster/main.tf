provider "aws" {
  region = "eu-central-1"
}

terraform {
  backend "s3" {
    bucket = "terrafom-run-and-running-state-devopscoder331"
    key = "stage/services/webserver-cluster/terraform.tfstate"
    region = "eu-central-1"

    dynamodb_table = "terraform-up-and-running-lock"
    encrypt = true
  }
}

data "terrafom_remote_state" "db" {
  backend = "s3"

  config {
    bucket = "terrafom-run-and-running-state-devopscoder331"
    key = "stage/data-stores/mysql/terraform.tfstate"
    region = "eu-central-1"
  }
}


resource "aws_launch_configuration" "example" {
  image_id = "ami-0d359437d1756caa8"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.instance2.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, world" > index.html
              hostname | tee -a index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier = data.aws_subnet_ids.default.ids

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

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

resource "aws_security_group" "alb" {
    name = "terraform-example-alb"

    # allow all input http request
    ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    # allow all output request
    egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

resource "aws_lb" "example" {
  name = "terraform-asg-example"
  load_balancer_type  = "application"
  subnets = data.aws_subnet_ids.default.ids
  security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.example.arn
    port = 80
    protocol = "HTTP"

    # default response simple list with code 404
    default_action {
      type = "fixed-response"

      fixed_response {
        content_type = "text/plain"
        message_body = "404: page not found"
        status_code = 404
      }
    }
}

resource "aws_lb_target_group" "asg" {
  name = "terraform-asg-example"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 15
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100

  condition {
    field = "path-pattern"
    values = ["*"]
  }

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}
