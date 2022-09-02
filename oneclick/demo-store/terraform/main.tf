/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */



locals {
  _prefix = var.project_id
  _prefix_first_element           = element(split("-", local._prefix), 0)
  _useradmin_fqn                  = format("admin@%s", var.org_id)
  _sample_data_git_repo           = "https://github.com/anagha-google/dataplex-on-gcp-lab-resources"
  _data_gen_git_repo              = "https://github.com/mansim07/datamesh-datagenerator"
  _metastore_service_name         = "metastore-service"
  _customers_bucket_name          = format("%s_%s_customers_raw_data", local._prefix_first_element, var.rand)
  _customers_curated_bucket_name  = format("%s_%s_customers_curated_data", local._prefix_first_element, var.rand)
  _transactions_bucket_name       = format("%s_%s_trasactions_raw_data", local._prefix_first_element, var.rand)
  _transactions_curated_bucket_name  = format("%s_%s_trasactions_curated_data", local._prefix_first_element, var.rand)
  _transactions_ref_bucket_name   = format("%s_%s_transactions_ref_raw_data", local._prefix_first_element, var.rand)
  _merchants_bucket_name          = format("%s_%s_merchants_raw_data", local._prefix_first_element, var.rand)
  _merchants_curated_bucket_name  = format("%s_%s_merchants_curated_data", local._prefix_first_element, var.rand)
  _dataplex_process_bucket_name   = format("%s_%s__dataplex_process", local._prefix_first_element, var.rand) 
  _dataplex_bqtemp_bucket_name    = format("%s_%s_dataplex_temp", local._prefix_first_element, var.rand) 
}

provider "google" {
  project = var.project_id
  region  = var.location
}


data "google_project" "project" {}

locals {
  _project_number = data.google_project.project.number
}


####################################################################################
# Resource for Network Creation                                                    #
# The project was not created with the default network.                            #
# This creates just the network/subnets we need.                                   #
####################################################################################

resource "google_compute_network" "default_network" {
  project                 = var.project_id
  name                    = "vpc-main"
  description             = "Default network"
  auto_create_subnetworks = false
  mtu                     = 1460
}


####################################################################################
# Resource for Subnet                                                              #
#This creates just the subnets we need                                             #
####################################################################################

resource "google_compute_subnetwork" "main_subnet" {
  project       = var.project_id
  name          = format("%s-misc-subnet", local._prefix)
  ip_cidr_range = var.ip_range
  region        = var.location
  network       = google_compute_network.default_network.id
  depends_on = [
    google_compute_network.default_network,
  ]
}

####################################################################################
# Resource for Firewall rule                                                       #
####################################################################################

resource "google_compute_firewall" "firewall_rule" {
  project  = var.project_id
  name     = format("allow-intra-%s-misc-subnet", local._prefix)
  network  = google_compute_network.default_network.id

  direction = "INGRESS"

  allow {
    protocol = "all"
  }
  
  source_ranges = [ var.ip_range ]
  depends_on = [
    google_compute_subnetwork.main_subnet
  ]
}

resource "google_compute_firewall" "user_firewall_rule" {
  project  = var.project_id
  name     = format("allow-ingress-from-office-%s", local._prefix)
  network  = google_compute_network.default_network.id

  direction = "INGRESS"

  allow {
    protocol = "all"
  }

  source_ranges = [ var.user_ip_range ]
  depends_on = [
    google_compute_subnetwork.main_subnet
  ]
}

/*******************************************
Introducing sleep to minimize errors from
dependencies having not completed
********************************************/
resource "time_sleep" "sleep_after_network_and_iam_steps" {
  create_duration = "120s"
  depends_on = [
                google_compute_firewall.user_firewall_rule              ]
}


module "stage_data" {
  # Run this as the currently logged in user or the service account (assuming DevOps)
  source                                = "./modules/stage_data"
  project_id                            = var.project_id
  data_gen_git_repo                     = local._data_gen_git_repo
  location                              = var.location
  date_partition                        = var.date_partition
  tmpdir                                = var.tmpdir
  customers_bucket_name                 = local._customers_bucket_name
  customers_curated_bucket_name         = local._customers_curated_bucket_name
  merchants_bucket_name                 = local._merchants_bucket_name
  merchants_curated_bucket_name         = local._merchants_curated_bucket_name
  transactions_bucket_name              = local._transactions_bucket_name
  transactions_curated_bucket_name      = local._transactions_curated_bucket_name
  transactions_ref_bucket_name          = local._transactions_ref_bucket_name

  depends_on = [time_sleep.sleep_after_network_and_iam_steps]
}

