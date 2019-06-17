terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "Hashicorp-neh-Demo"

    workspaces {
      prefix = "remote-backend-"
    }
  }
}
