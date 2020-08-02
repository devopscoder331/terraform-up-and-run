variable "server_port" {
  description = "The port the server will use for http request"
  type = number
  default = 8080
}

variable "cluster_name" {
  default = ""
  type = string
}

variable "db_remote_state_bucket" {
  default = ""
  type = string
}

variable "db_remote_state_key" {
  default = ""
  type = string
}
