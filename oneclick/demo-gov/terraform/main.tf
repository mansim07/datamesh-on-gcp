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
  _prefix = var.project_id_governance
  _bucket_prefix = var.project_id_storage
  #_random = var.rand
  _prefix_first_element           =  local._prefix #element(split("-", local._prefix), 0)
  #_prefix_datastore               = element(split("-", var.datastore_project_id), 0)
  #_prefix_datastore_first_element = element(split("-", local._prefix_datastore), 0)
  _useradmin_fqn                  = format("admin@%s.altostrat.com", var.ldap)
  _sample_data_git_repo           = "https://github.com/anagha-google/dataplex-on-gcp-lab-resources"
  _data_gen_git_repo              = "https://github.com/mansim07/datamesh-datagenerator"
  _metastore_service_name         = "metastore-service"
  _customers_bucket_name          = format("%s_customers_raw_data", local._bucket_prefix)
  _customers_curated_bucket_name  = format("%s_customers_curated_data", local._bucket_prefix)
  _transactions_bucket_name       = format("%s_trasactions_raw_data", local._bucket_prefix)
  _transactions_curated_bucket_name  = format("%s_trasactions_curated_data", local._bucket_prefix)
  _transactions_ref_bucket_name   = format("%s_transactions_ref_raw_data", local._bucket_prefix)
  _merchants_bucket_name          = format("%s_merchants_raw_data", local._bucket_prefix)
  _merchants_curated_bucket_name  = format("%s_merchants_curated_data", local._bucket_prefix)
  _dataplex_process_bucket_name   = format("%s_dataplex_process", local._prefix) 
  _dataplex_bqtemp_bucket_name    = format("%s_dataplex_temp", local._prefix) 
}

provider "google" {
  project = var.project_id_governance
  region  = var.location
}

resource "google_service_account" "service_account" {
  project      = var.project_id_governance
  account_id   =  format("%s-admin-sa", var.project_id_governance)
  display_name = "Demo Service Account"
}
 


resource "google_service_account" "dq_service_account" {
  project      = var.project_id_governance
  account_id   =  format("%s-dq-sa", var.project_id_governance)
  display_name = "Data Quality Admin Service Account"
}


resource "google_service_account" "data_service_account" {
  project      = var.project_id_governance
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
  project  = var.project_id_governance
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
  project  = var.project_id_governance
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
  project  = var.project_id_governance
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
"roles/dataproc.worker",
"roles/cloudscheduler.jobRunner"
])
  project  = var.project_id_governance
  role     = each.key
  member   = format("serviceAccount:customer-sa@%s.iam.gserviceaccount.com", var.project_id_governance)

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
"roles/dataplex.editor",
"roles/dataplex.developer",
"roles/dataplex.metadataReader",
"roles/dataplex.metadataWriter",
"roles/metastore.metadataEditor",
"roles/metastore.serviceAgent",
"roles/dataproc.worker",
"roles/storage.objectAdmin",
"roles/dataflow.admin",
"roles/dataflow.worker",
"roles/cloudscheduler.jobRunner"
])
  project  = var.project_id_governance
  role     = each.key
  member   = format("serviceAccount:merchant-sa@%s.iam.gserviceaccount.com", var.project_id_governance)

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
"roles/dataplex.editor",
"roles/dataplex.developer",
"roles/dataplex.metadataReader",
"roles/dataplex.metadataWriter",
"roles/metastore.metadataEditor",
"roles/metastore.serviceAgent",
"roles/dataproc.worker",
"roles/storage.objectAdmin",
"roles/dataflow.admin",
"roles/dataflow.worker",
"roles/cloudscheduler.jobRunner"
])
  project  = var.project_id_governance
  role     = each.key
  member   = format("serviceAccount:cc-trans-sa@%s.iam.gserviceaccount.com", var.project_id_governance)

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
"roles/dataplex.editor",
"roles/dataplex.developer",
"roles/dataplex.metadataReader",
"roles/dataplex.metadataWriter",
"roles/metastore.metadataEditor",
"roles/metastore.serviceAgent",
"roles/dataproc.worker",
"roles/storage.objectAdmin",
"roles/dataflow.admin",
"roles/dataflow.worker",
"roles/cloudscheduler.jobRunner"
])
  project  = var.project_id_governance
  role     = each.key
  member   = format("serviceAccount:cc-trans-consumer-sa@%s.iam.gserviceaccount.com", var.project_id_governance)

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
  project                 = var.project_id_governance
  name                    = "default"
  description             = "Default network"
  auto_create_subnetworks = false
  mtu                     = 1460
}


####################################################################################
# Resource for Subnet                                                              #
#This creates just the subnets we need                                             #
####################################################################################

resource "google_compute_subnetwork" "main_subnet" {
  project       = var.project_id_governance
  name          = "default"    #format("%s-misc-subnet", local._prefix)
  ip_cidr_range = var.ip_range
  region        = var.location
  network       = google_compute_network.default_network.id
  private_ip_google_access = true
  depends_on = [
    google_compute_network.default_network,
  ]
}

####################################################################################
# Resource for Firewall rule                                                       #
####################################################################################

resource "google_compute_firewall" "firewall_rule" {
  project  = var.project_id_governance
  name     = "allow-intra-default"    #format("allow-intra-%s-misc-subnet", local._prefix)
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
  project  = var.project_id_governance
  name     = "allow-ingress-from-office-default"   #format("allow-ingress-from-office-%s", local._prefix)
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

/*
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
  */
resource "google_storage_bucket" "storage_bucket_process" {
  project                     = var.project_id_governance
  name                        = local._dataplex_process_bucket_name
  location                    = var.location
  force_destroy               = true
  uniform_bucket_level_access = true

  depends_on = [time_sleep.sleep_after_network_and_iam_steps]
}

resource "google_storage_bucket" "storage_bucket_bqtemp" {
  project                     = var.project_id_governance
  name                        = local._dataplex_bqtemp_bucket_name
  location                    = var.location
  force_destroy               = true
  uniform_bucket_level_access = true

  depends_on = [time_sleep.sleep_after_network_and_iam_steps]
}


####################################################################################
# Create BigQuery Datasets
####################################################################################

resource "google_bigquery_dataset" "bigquery_datasets" {
  for_each = toset([ 
   "central_dlp_data",
   "central_audit_data",
   "central_dq_results",
   "enterprise_reference_data"
  ])
  project                     = var.project_id_governance
  dataset_id                  = each.key
  friendly_name               = each.key
  description                 = "${each.key} Dataset for Dataplex Demo"
  location                    = var.location
  delete_contents_on_destroy  = true
  
  depends_on = [time_sleep.sleep_after_network_and_iam_steps]
}

resource "null_resource" "gsutil_resources" {
  provisioner "local-exec" {
    command = <<-EOT
      cd ../resources/marsbank-datagovernance-process
      gsutil -u ${var.project_id_governance} cp gs://dataplex-dataproc-templates-artifacts/* ./common/.
      cp ../../../../demo_artifacts/libs/tagmanager-1.0-SNAPSHOT.jar ./common/.
      java -cp common/tagmanager-1.0-SNAPSHOT.jar  com.google.cloud.dataplex.setup.CreateTagTemplates ${var.project_id_governance} ${var.location} data_product_information
      java -cp common/tagmanager-1.0-SNAPSHOT.jar  com.google.cloud.dataplex.setup.CreateTagTemplates ${var.project_id_governance} ${var.location} data_product_classification
      java -cp common/tagmanager-1.0-SNAPSHOT.jar  com.google.cloud.dataplex.setup.CreateTagTemplates ${var.project_id_governance} ${var.location} data_product_quality
      java -cp common/tagmanager-1.0-SNAPSHOT.jar  com.google.cloud.dataplex.setup.CreateTagTemplates ${var.project_id_governance} ${var.location} data_product_exchange
      java -cp common/tagmanager-1.0-SNAPSHOT.jar  com.google.cloud.dataplex.setup.CreateDLPInspectionTemplate ${var.project_id_storage} global marsbank_dlp_template
      sed -i s/_project_datagov_/${var.project_id_governance}/g merchant-source-configs/dq_merchant_data_product.yaml
      sed -i s/_project_datagov_/${var.project_id_governance}/g merchant-source-configs/dq_merchant_gcs_data.yaml
      sed -i s/_project_datagov_/${var.project_id_governance}/g customer-source-configs/dq_customer_data_product.yaml
      sed -i s/_project_datagov_/${var.project_id_governance}/g customer-source-configs/dq_customer_gcs_data.yaml
      sed -i s/_project_datagov_/${var.project_id_governance}/g customer-source-configs/dq_tokenized_customer_data_product.yaml
      sed -i s/_project_datagov_/${var.project_id_governance}/g transactions-source-configs/dq_transactions_data_product.yaml
      sed -i s/_project_datagov_/${var.project_id_governance}/g transactions-source-configs/dq_transactions_gcs_data.yaml
      sed -i s/_project_datagov_/${var.project_id_governance}/g transactions-consumer-configs/dq_cc_analytics_data_product.yaml
      sed -i s/_project_datagov_/${var.project_id_governance}/g merchant-source-configs/data-product-classification-tag-auto.yaml
      sed -i s/_project_datagov_/${var.project_id_governance}/g customer-source-configs/data-product-classification-tag-auto.yaml
      sed -i s/_project_datagov_/${var.project_id_governance}/g transactions-source-configs/data-product-classification-tag-auto.yaml
      sed -i s/_project_datagov_/${var.project_id_governance}/g transactions-consumer-configs/data-product-classification-tag-auto.yaml
      sed -i s/_project_datagov_/${var.project_id_governance}/g merchant-source-configs/data-product-quality-tag-auto.yaml
      sed -i s/_project_datagov_/${var.project_id_governance}/g customer-source-configs/data-product-quality-tag-auto.yaml
      sed -i s/_project_datagov_/${var.project_id_governance}/g transactions-source-configs/data-product-quality-tag-auto.yaml
      sed -i s/_project_datagov_/${var.project_id_governance}/g transactions-consumer-configs/data-product-quality-tag-auto.yaml
      gsutil -m cp -r * gs://${local._dataplex_process_bucket_name}
    EOT
    }
    depends_on = [
                  google_bigquery_dataset.bigquery_datasets,
                  google_storage_bucket.storage_bucket_process,
                  google_storage_bucket.storage_bucket_bqtemp]

  }




####################################################################################
# Organize the Data
####################################################################################
module "organize_data" {
  # Run this as the currently logged in user or the service account (assuming DevOps)
  source                 = "./modules/organize_data"
  #metastore_service_name = local._metastore_service_name
  project_id             = var.project_id_governance
  location               = var.location
  lake_name              = var.lake_name
  project_number         = local._project_number
  datastore_project_id   = var.project_id_storage
   
  #depends_on = [null_resource.dataproc_metastore]
  depends_on = [null_resource.gsutil_resources]

}

####################################################################################
# Register the Data Assets in Dataplex
####################################################################################
module "register_assets" {
  # Run this as the currently logged in user or the service account (assuming DevOps)
  source                                = "./modules/register_assets"
  project_id                            = var.project_id_governance
  location                              = var.location
  lake_name                             = var.lake_name
  customers_bucket_name                 = local._customers_bucket_name
  merchants_bucket_name                 = local._merchants_bucket_name
  transactions_bucket_name              = local._transactions_bucket_name
  transactions_ref_bucket_name          = local._transactions_ref_bucket_name
  customers_curated_bucket_name         = local._customers_curated_bucket_name
  merchants_curated_bucket_name         = local._merchants_curated_bucket_name
  transactions_curated_bucket_name      = local._transactions_curated_bucket_name
  datastore_project_id                  = var.project_id_storage
 
  depends_on = [module.organize_data]

}

####################################################################################
# Reuseable Modules
####################################################################################

module "composer" {
  # Run this as the currently logged in user or the service account (assuming DevOps)
  source                        = "./modules/composer"
  location                      = var.location
  network_id                    = google_compute_network.default_network.id
  project_id                    = var.project_id_governance
  datastore_project_id          = var.project_id_storage
  project_number                = local._project_number
  prefix                        = local._prefix_first_element
  dataplex_process_bucket_name  = local._dataplex_process_bucket_name
  
  depends_on = [module.register_assets]
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

