provider "aws" {
  region = "eu-central-1"
}

module "webserver-cluster" {
  source = "../../../modules/services/webserver-cluster/"
}
