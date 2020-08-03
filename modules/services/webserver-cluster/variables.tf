variable "server_port" {
  description = "The port the server will use for http request"
  type = number
  default = 8080
}

variable "cluster_name" {
  description = ""
  type = string
}

variable "db_remote_state_bucket" {
  description = ""
  type = string
}

variable "db_remote_state_key" {
  description = ""
  type = string
}

variable "instance_type" {
  description = "The type of EC2 Instance to run (e.g. t2.micro)"
  type = string
}

variable "min_size" {
  description = "The minimum number of EC2 Instance in the ASG"
  type = number
}

variable "max_size" {
  description = "The maximum number of EC2 Instance in the ASG"
  type = number
}
