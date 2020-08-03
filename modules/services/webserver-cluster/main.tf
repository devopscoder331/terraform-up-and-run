terraform {
  backend "s3" {
    bucket = "terrafom-run-and-running-state-devopscoder331"
    key = "stage/services/webserver-cluster/terraform.tfstate"
    region = "eu-central-1"

    dynamodb_table = "terraform-up-and-running-lock"
    encrypt = true
  }
}

locals {
  http_port = 80
  any_port = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips = ["0.0.0.0/0"]
}

data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = var.db_remote_state_bucket
    key = var.db_remote_state_key
    region = "eu-central-1"
  }
}

data "template_file" "user_data" {
  template = file("../../../modules/services/webserver-cluster/user_data.sh")

  vars = {
    server_port = var.server_port
    db_address = data.terraform_remote_state.db.outputs.address
    db_port = data.terraform_remote_state.db.outputs.port
  }
}

resource "aws_launch_configuration" "example" {
  image_id = "ami-0d359437d1756caa8"
  instance_type = var.instance_type
  security_groups = [aws_security_group.instance2.id]

  user_data = data.template_file.user_data.rendered

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier = data.aws_subnet_ids.default.ids

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  min_size = var.min_size
  max_size = var.max_size

  tag {
    key = "name"
    value = var.cluster_name
    propagate_at_launch = true
  }
}

resource "aws_security_group" "instance2" {
    name = "${var.cluster_name}-instance"

    ingress {
      from_port = var.server_port
      to_port = var.server_port
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "alb" {
    name = "${var.cluster_name}-alb"

    # allow all input http request
    ingress {
      from_port = local.http_port
      to_port = local.http_port
      protocol = local.tcp_protocol
      cidr_blocks = local.all_ips
    }

    # allow all output request
    egress {
      from_port = local.any_port
      to_port = local.any_port
      protocol = local.any_protocol
      cidr_blocks = local.all_ips
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
    port = local.http_port
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
