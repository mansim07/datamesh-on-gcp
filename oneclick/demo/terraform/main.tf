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
  _customers_bucket_name          = format("%s_bankofmars_retail_customers_source_data", local._prefix_first_element)
  _transactions_bucket_name       = format("%s_bankofmars_retail_merchants_data", local._prefix_first_element)
  _transactions_ref_bucket_name   = format("%s_bankofmars_retail_merchants_ref_data", local._prefix_first_element)
  _merchants_bucket_name          = format("%s_bankofmars_retail_credit_cards_trasactions_data", local._prefix_first_element)
  _dataplex_process_bucket_name   = format("%s_bankofmars_dataplex_process", local._prefix_first_element) 
}

provider "google" {
  project = var.project_id
  region  = var.location
}

resource "google_service_account" "service_account" {
  project      = var.project_id
  account_id   =  format("%s-admin-sa", var.project_id)
  display_name = "Demo Service Account"
}
 
resource "google_service_account" "dq_service_account" {
  project      = var.project_id
  account_id   =  format("%s-dq-sa", var.project_id)
  display_name = "Data Quality Admin Service Account"
}

/* Dq roles */
resource "google_project_iam_member" "dqservice_account_owner" {
  for_each = toset([
"roles/bigquery.dataEditor",
"roles/bigquery.jobUser",
"roles/serviceusage.serviceUsageConsumer",
"roles/storage.objectViewer",
"roles/dataplex.dataReader",
"roles/dataplex.metadataReader"])
  project  = var.project_id
  role     = each.key
  member   = "serviceAccount:${google_service_account.dq_service_account.email}"
  depends_on = [
    google_service_account.dq_service_account
  ]
}

resource "google_project_iam_member" "service_account_owner" {
  for_each = toset([
"roles/iam.serviceAccountUser",
"roles/iam.serviceAccountTokenCreator",
"roles/bigquery.dataEditor",
"roles/bigquery.admin",
"roles/metastore.admin",
"roles/metastore.editor",
"roles/metastore.serviceAgent",
"roles/storage.admin",
"roles/dataplex.editor",
"roles/dataproc.admin",
"roles/dataproc.worker"
  ])
  project  = var.project_id
  role     = each.key
  member   = "serviceAccount:${google_service_account.service_account.email}"
  depends_on = [
    google_service_account.service_account
  ]
}
 
 
resource "google_project_iam_member" "user_account_owner" {
  for_each = toset([
"roles/iam.serviceAccountUser",
"roles/iam.serviceAccountTokenCreator",
"roles/bigquery.user",
"roles/bigquery.dataEditor",
"roles/bigquery.jobUser",
"roles/bigquery.admin",
"roles/storage.admin",
"roles/dataplex.admin",
"roles/dataplex.editor"
  ])
  project  = var.project_id
  role     = each.key
  member   = "user:${local._useradmin_fqn}"
}

resource "google_service_account_iam_binding" "admin_account_iam" {
  for_each = toset([
    "roles/iam.serviceAccountUser",
    "roles/iam.serviceAccountTokenCreator"
    ])
  role               = each.key

  service_account_id = google_service_account.service_account.name
  members = [
    "user:${local._useradmin_fqn}"
  ]

    depends_on = [
    google_service_account.service_account
  ]

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
  create_duration = "240s"
  depends_on = [
                google_compute_firewall.user_firewall_rule,
                google_service_account_iam_binding.admin_account_iam,
                google_project_iam_member.user_account_owner,
                google_project_iam_member.service_account_owner  
              ]
}

resource "null_resource" "dataproc_metastore" {
  provisioner "local-exec" {
    command = format("gcloud beta metastore services create %s --location=%s --network=%s --port=9083 --tier=Developer --hive-metastore-version=%s --impersonate-service-account=%s --endpoint-protocol=GRPC", 
                     local._metastore_service_name,
                     var.location,
                     google_compute_network.default_network.name,
                     var.hive_metastore_version,
                     google_service_account.service_account.email)
  }

  depends_on = [time_sleep.sleep_after_network_and_iam_steps]
}


####################################################################################
# Reuseable Modules
####################################################################################

module "stage_data" {
  # Run this as the currently logged in user or the service account (assuming DevOps)
  source                        = "./modules/stage_data"
  project_id                    = var.project_id
  data_gen_git_repo             = local._data_gen_git_repo
  location                      = var.location
  date_partition                = var.date_partition
  tmpdir                        = var.tmpdir
  customers_bucket_name         = local._customers_bucket_name
  merchants_bucket_name         = local._merchants_bucket_name
  transactions_bucket_name      = local._transactions_bucket_name
  transactions_ref_bucket_name  = local._transactions_ref_bucket_name
  dataplex_process_bucket_name  = local._dataplex_process_bucket_name
  depends_on = [null_resource.dataproc_metastore]
}

####################################################################################
# Organize the Data
####################################################################################
module "organize_data" {
  # Run this as the currently logged in user or the service account (assuming DevOps)
  source                 = "./modules/organize_data"
  metastore_service_name = local._metastore_service_name
  project_id             = var.project_id
  location               = var.location
  lake_name              = var.lake_name

  depends_on = [module.stage_data]

}

####################################################################################
# Register the Data Assets in Dataplex
####################################################################################
module "register_assets" {
  # Run this as the currently logged in user or the service account (assuming DevOps)
  source                        = "./modules/register_assets"
  project_id                    = var.project_id
  location                      = var.location
  lake_name                     = var.lake_name
  customers_bucket_name         = local._customers_bucket_name
  merchants_bucket_name         = local._merchants_bucket_name
  transactions_bucket_name      = local._transactions_bucket_name
  transactions_ref_bucket_name  = local._transactions_ref_bucket_name
  depends_on = [module.organize_data]

}

/*
####################################################################################
# Run the Data Quality Tests
####################################################################################
module "process_data" {
  # Run this as the currently logged in user or the service account (assuming DevOps)
  source          = "./modules/process_data"
  
  depends_on = [module.register_assets]

}

*/
########################################################################################
#NULL RESOURCE FOR DELAY/TIMER/SLEEP                                                   #
#TO GIVE TIME TO RESOURCE TO COMPLETE ITS CREATION THEN DEPENDANT RESOURCE WILL CREATE #
########################################################################################
/*
resource "time_sleep" "wait_X_seconds" {
  depends_on = [google_resource.resource_name]

  create_duration = "Xs"
}
*/

