terraform {
  required_providers {
    google = {
      source  = "google"
      version = "~> 4.56.0"
    }
  }
}

provider "google" {}

locals {
  project_id = "mbdatagov-965428591"
  datastore_project_id = "mbdatastore-965428591"
}
