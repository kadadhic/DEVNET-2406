terraform {
  required_providers {
    fmc = {
      source = "CiscoDevNet/fmc"
      version = "2.0.0-rc9"
    }
  }
}

provider "fmc" {
  url      = var.cdfmc_url
  token    = var.cdfmc_token
}