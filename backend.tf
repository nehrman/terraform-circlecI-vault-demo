terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "Hashicorp-neh-Demo"
    token = "${tfe_token}"

    workspaces {
      prefix = "remote-backend-"
    }
  }
}
