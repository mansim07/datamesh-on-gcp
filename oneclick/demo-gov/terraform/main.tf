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
  _random = var.rand
  _prefix_first_element           = element(split("-", local._prefix), 0)
  _prefix_datastore               = element(split("-", var.datastore_project_id), 0)
  _useradmin_fqn                  = format("admin@%s", var.org_id)
  _sample_data_git_repo           = "https://github.com/anagha-google/dataplex-on-gcp-lab-resources"
  _data_gen_git_repo              = "https://github.com/mansim07/datamesh-datagenerator"
  _metastore_service_name         = "metastore-service"
  _customers_bucket_name          = format("%s_%s_datastore_customers_raw_data", local._prefix_datastore, var.rand)
  _customers_curated_bucket_name  = format("%s_%s_datastore_customers_curated_data", local._prefix_datastore, var.rand)
  _transactions_bucket_name       = format("%s_%s_datastore_trasactions_raw_data", local._prefix_datastore,  var.rand)
  _transactions_curated_bucket_name  = format("%s_%s_datastore_trasactions_curated_data", local._prefix_datastore, var.rand)
  _transactions_ref_bucket_name   = format("%s_%s_datastore_transactions_ref_raw_data", local._prefix_datastore, var.rand)
  _merchants_bucket_name          = format("%s_%s_datastore_merchants_raw_data", local._prefix_datastore, var.rand)
  _merchants_curated_bucket_name  = format("%s_%s_datastore_merchants_curated_data", local._prefix_datastore, var.rand)
  _dataplex_process_bucket_name   = format("%s_%s_datagov_dataplex_process", local._prefix_datastore, var.rand) 
  _dataplex_bqtemp_bucket_name    = format("%s_%s_datagov_dataplex_temp", local._prefix_datastore, var.rand) 
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

resource "google_service_account" "data_service_account" {
  project      = var.project_id
   for_each = {
    "customer-sa" : "customer-sa",
    "merchant-sa" : "merchant-sa",
    "cc-trans-consumer-sa" : "cc-trans-consumer-sa",
    "cc-trans-sa" : "cc-trans-sa"
    }
  account_id   = format("%s", each.key)
  display_name = format("Demo Service Account %s", each.value)
}

data "google_project" "project" {}

locals {
  _project_number = data.google_project.project.number
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

resource "google_project_iam_member" "iam_customer_sa" {
  for_each = toset([
"roles/iam.serviceAccountUser",
"roles/iam.serviceAccountTokenCreator",
"roles/serviceusage.serviceUsageConsumer",
"roles/bigquery.user",
"roles/bigquery.jobUser",
"roles/dataflow.worker",
"roles/dataplex.developer",
"roles/dataplex.metadataReader",
"roles/dataplex.metadataWriter",
"roles/metastore.metadataEditor",
"roles/metastore.serviceAgent",
"roles/dataproc.worker"
])
  project  = var.project_id
  role     = each.key
  member   = format("serviceAccount:customer-sa@%s.iam.gserviceaccount.com", var.project_id)

  depends_on = [
    google_service_account.data_service_account
  ]

}

resource "google_project_iam_member" "iam_merchant_sa" {
  for_each = toset([
"roles/iam.serviceAccountUser",
"roles/iam.serviceAccountTokenCreator",
"roles/serviceusage.serviceUsageConsumer",
"roles/artifactregistry.reader",
"roles/bigquery.user",
"roles/bigquery.jobUser",
"roles/dataflow.worker",
"roles/dataplex.developer",
"roles/dataplex.metadataReader",
"roles/dataplex.metadataWriter",
"roles/metastore.metadataEditor",
"roles/metastore.serviceAgent",
"roles/dataproc.worker",
"roles/storage.objectAdmin",
"roles/dataflow.admin",
"roles/dataflow.worker"
])
  project  = var.project_id
  role     = each.key
  member   = format("serviceAccount:merchant-sa@%s.iam.gserviceaccount.com", var.project_id)

  depends_on = [
    google_service_account.data_service_account
  ]
}

resource "google_project_iam_member" "iam_cc_trans_sa" {
  for_each = toset([
"roles/iam.serviceAccountUser",
"roles/iam.serviceAccountTokenCreator",
"roles/serviceusage.serviceUsageConsumer",
"roles/artifactregistry.reader",
"roles/bigquery.user",
"roles/bigquery.jobUser",
"roles/dataflow.worker",
"roles/dataplex.developer",
"roles/dataplex.metadataReader",
"roles/dataplex.metadataWriter",
"roles/metastore.metadataEditor",
"roles/metastore.serviceAgent",
"roles/dataproc.worker",
"roles/storage.objectAdmin",
"roles/dataflow.admin",
"roles/dataflow.worker"
])
  project  = var.project_id
  role     = each.key
  member   = format("serviceAccount:cc-trans-sa@%s.iam.gserviceaccount.com", var.project_id)

  depends_on = [
    google_service_account.data_service_account
  ]
}

resource "google_project_iam_member" "iam_cc_trans_consumer_sa" {
  for_each = toset([
"roles/iam.serviceAccountUser",
"roles/iam.serviceAccountTokenCreator",
"roles/serviceusage.serviceUsageConsumer",
"roles/artifactregistry.reader",
"roles/bigquery.user",
"roles/bigquery.jobUser",
"roles/dataflow.worker",
"roles/dataplex.developer",
"roles/dataplex.metadataReader",
"roles/dataplex.metadataWriter",
"roles/metastore.metadataEditor",
"roles/metastore.serviceAgent",
"roles/dataproc.worker",
"roles/storage.objectAdmin",
"roles/dataflow.admin",
"roles/dataflow.worker"
])
  project  = var.project_id
  role     = each.key
  member   = format("serviceAccount:cc-trans-consumer-sa@%s.iam.gserviceaccount.com", var.project_id)

  depends_on = [
    google_service_account.data_service_account
  ]
}

resource "google_service_account_iam_binding" "admin_account_iam" {
  role               = "roles/iam.serviceAccountTokenCreator"

  service_account_id = google_service_account.service_account.name
  members = [
    "user:${local._useradmin_fqn}"
  ]

    depends_on = [
    google_service_account.service_account
  ]

}

/*
resource "google_service_account_iam_binding" "data_admin_account_iam" {
  role               = "roles/iam.serviceAccountUser"
  for_each = toset([
    "customer-sa",
    "merchant-sa",
    "cc-trans-consumer-sa",
    format("%s-dq-sa", var.project_id),
    format("%s-admin-sa", var.project_id)
  ])
    service_account_id = format("%s@%s.iam.gserviceaccount.com", each.key, var.project_id,)
  
  members = [
    "user:${local._useradmin_fqn}"
  ]

    depends_on = [
    google_service_account.service_account
  ]

}
*/

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

resource "google_storage_bucket" "storage_bucket_process" {
  project                     = var.project_id
  name                        = local._dataplex_process_bucket_name
  location                    = var.location
  force_destroy               = true
  uniform_bucket_level_access = true

  depends_on = [time_sleep.sleep_after_network_and_iam_steps]
}

resource "google_storage_bucket" "storage_bucket_bqtemp" {
  project                     = var.project_id
  name                        = local._dataplex_bqtemp_bucket_name
  location                    = var.location
  force_destroy               = true
  uniform_bucket_level_access = true

  depends_on = [time_sleep.sleep_after_network_and_iam_steps]
}

resource "null_resource" "gsutil_resources" {
  provisioner "local-exec" {
    command = <<-EOT
      cd ../resources/marsbank-datagovernance-process
      gsutil -u ${var.project_id} cp gs://dataplex-dataproc-templates-artifacts/* ./common/.
      cp ../../../../demo_artifacts/libs/tagmanager-1.0-SNAPSHOT.jar ./common/.
      java -cp common/tagmanager-1.0-SNAPSHOT.jar  com.google.cloud.dataplex.setup.CreateTagTemplates ${var.project_id} ${var.location} data_product_information
      java -cp common/tagmanager-1.0-SNAPSHOT.jar  com.google.cloud.dataplex.setup.CreateTagTemplates ${var.project_id} ${var.location} data_product_classification
      java -cp common/tagmanager-1.0-SNAPSHOT.jar  com.google.cloud.dataplex.setup.CreateTagTemplates ${var.project_id} ${var.location} data_product_quality
      java -cp common/tagmanager-1.0-SNAPSHOT.jar  com.google.cloud.dataplex.setup.CreateTagTemplates ${var.project_id} global data_product_exchange
      gsutil -m cp -r * gs://${local._dataplex_process_bucket_name}
    EOT
    }
    depends_on = [google_storage_bucket.storage_bucket_process]

  }

####################################################################################
# Reuseable Modules
####################################################################################
module "composer" {
  # Run this as the currently logged in user or the service account (assuming DevOps)
  source                        = "./modules/composer"
  location                      = var.location
  network_id                    = google_compute_network.default_network.id
  project_id                    = var.project_id
  datastore_project_id          = var.datastore_project_id
  project_number                = local._project_number
  prefix                        = local._prefix_first_element
  dataplex_process_bucket_name  = local._dataplex_process_bucket_name
  
  depends_on = [time_sleep.sleep_after_network_and_iam_steps]
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
  project_number         = local._project_number
  datastore_project_id   = var.datastore_project_id

  depends_on = [null_resource.dataproc_metastore]

}

####################################################################################
# Register the Data Assets in Dataplex
####################################################################################
module "register_assets" {
  # Run this as the currently logged in user or the service account (assuming DevOps)
  source                                = "./modules/register_assets"
  project_id                            = var.project_id
  location                              = var.location
  lake_name                             = var.lake_name
  customers_bucket_name                 = local._customers_bucket_name
  merchants_bucket_name                 = local._merchants_bucket_name
  transactions_bucket_name              = local._transactions_bucket_name
  transactions_ref_bucket_name          = local._transactions_ref_bucket_name
  customers_curated_bucket_name         = local._customers_curated_bucket_name
  merchants_curated_bucket_name         = local._merchants_curated_bucket_name
  transactions_curated_bucket_name      = local._transactions_curated_bucket_name
  datastore_project_id                  = var.datastore_project_id
  depends_on = [module.organize_data]

}

/*
Data pipelines will be done in composer for initial enablement
####################################################################################
# Run the Data Pipelines
####################################################################################
module "process_data" {
  # Run this as the currently logged in user or the service account (assuming DevOps)
  source          = "./modules/process_data"
  project_id                            = var.project_id
  location                              = var.location
  dataplex_process_bucket_name          = local._dataplex_process_bucket_name
  dataplex_bqtemp_bucket_name           = local._dataplex_bqtemp_bucket_name

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

