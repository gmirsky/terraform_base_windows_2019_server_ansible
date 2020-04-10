terraform {
  required_version = ">= 0.12"
  backend "local" {
    path = "./tfstate/terraform.tfstate"
  }
}
