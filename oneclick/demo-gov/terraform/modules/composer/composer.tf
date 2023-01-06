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

####################################################################################
# Variables
####################################################################################
variable "project_id" {}
variable "datastore_project_id" {}
variable "project_number" {}
variable "location" {}
variable "network_id" {}
variable "prefix" {}
variable "dataplex_process_bucket_name" {}


locals {
_dataplex_process_bucket_name   = format("%s_dataplex_process",var.project_id) 
}


####################################################################################
# Composer 2
####################################################################################
# Cloud Composer v2 API Service Agent Extension
# The below does not overwrite at the Org level like GCP docs: https://cloud.google.com/composer/docs/composer-2/create-environments#terraform
resource "google_project_iam_member" "cloudcomposer_account_service_agent_v2_ext" {
  project  = var.project_id
  role     = "roles/composer.ServiceAgentV2Ext"
  member   = "serviceAccount:service-${var.project_number}@cloudcomposer-accounts.iam.gserviceaccount.com"
}

# Cloud Composer API Service Agent
resource "google_project_iam_member" "cloudcomposer_account_service_agent" {
  project  = var.project_id
  role     = "roles/composer.serviceAgent"
  member   = "serviceAccount:service-${var.project_number}@cloudcomposer-accounts.iam.gserviceaccount.com"

  depends_on = [
    google_project_iam_member.cloudcomposer_account_service_agent_v2_ext
  ]
}

resource "google_project_iam_member" "composer_service_account_worker_role" {
  project  = var.project_id
  role     = "roles/composer.worker"
  member   = "serviceAccount:${google_service_account.composer_service_account.email}"

  depends_on = [
    google_service_account.composer_service_account
  ]
}


resource "google_compute_subnetwork" "composer_subnet" {
  project       = var.project_id
  name          = "composer-subnet"
  ip_cidr_range = "10.2.0.0/16"
  region        = var.location
  network       = var.network_id

}

resource "google_service_account" "composer_service_account" {
  project      = var.project_id
  account_id   = "composer-service-account"
  display_name = "Service Account for Composer Environment"
}


# Let composer impersonation the service account that can change org policies (for demo purposes)
resource "google_service_account_iam_member" "cloudcomposer_service_account_impersonation" {
  service_account_id ="projects/${var.project_id}/serviceAccounts/f${var.project_number}-admin-sa@${var.project_id}.iam.gserviceaccount.com"
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.composer_service_account.email}"
  depends_on         = [ google_service_account.composer_service_account ]
}

# ActAs role
resource "google_project_iam_member" "cloudcomposer_act_as" {
  project  = var.project_id
  role     = "roles/iam.serviceAccountUser"
  member   = "serviceAccount:${google_service_account.composer_service_account.email}"

  depends_on = [
    google_service_account_iam_member.cloudcomposer_service_account_impersonation
  ]
}




# ActAs role
resource "google_project_iam_member" "cloudcomposer_admin" {
  project  = var.project_id
  role     = "roles/composer.admin"
  member   = "serviceAccount:${google_service_account.composer_service_account.email}"

  depends_on = [
    google_project_iam_member.cloudcomposer_act_as
  ]
}


resource "google_project_iam_member" "cloudcomposer_editorrole" {
  project  = var.project_id
  role     = "roles/editor"
  member   = "serviceAccount:${google_service_account.composer_service_account.email}"

  depends_on = [
    google_project_iam_member.cloudcomposer_admin
  ]
}

resource "google_project_iam_member" "cloudcomposer_tokencreator" {
  project  = var.project_id
  role     = "roles/iam.serviceAccountTokenCreator"
  member   = "serviceAccount:${google_service_account.composer_service_account.email}"

  depends_on = [
    google_project_iam_member.cloudcomposer_editorrole
  ]
}



resource "google_composer_environment" "composer_env" {
  project  = var.project_id
  name     = format("%s-composer", var.project_id) 
  region   = var.location

  config {

    software_config {
      image_version = "composer-2.0.25-airflow-2.2.5"
      #"composer-2.0.7-airflow-2.2.3"

      pypi_packages = {
        #google-cloud-dataplex = ">=0.1.0"
        requests_oauth2 = ""
       # scipy = "==1.1.0"
      }

      env_variables = {
        
        AIRFLOW_VAR_CUST_ENTITY_LIST_FILE_PATH = "/home/airflow/gcs/data/customer_data_products/entities.txt",
        AIRFLOW_VAR_CUSTOMER_DC_INFO_INPUT_PATH = "gs://${var.dataplex_process_bucket_name}/customer-source-configs",
        AIRFLOW_VAR_CUSTOMER_DC_INPUT_FILE = "data-product-classification-tag-auto.yaml",
        AIRFLOW_VAR_CUSTOMER_DP_INFO_INPUT_FILE = "data-product-info-tag-auto.yaml",
        AIRFLOW_VAR_CUSTOMER_DP_INFO_INPUT_PATH = "gs://${var.dataplex_process_bucket_name}/customer-source-configs",
        AIRFLOW_VAR_CUSTOMER_DPLX_LAKE_ID = "prod-customer-source-domain",
        AIRFLOW_VAR_CUSTOMER_DPLX_REGION = "${var.location}",
        AIRFLOW_VAR_CUSTOMER_DPLX_ZONE_ID = "customer-data-product-zone",
        AIRFLOW_VAR_CUSTOMER_DQ_INFO_INPUT_PATH = "gs://${var.dataplex_process_bucket_name}/customer-source-configs",
        AIRFLOW_VAR_CUSTOMER_DQ_INPUT_FILE = "data-product-quality-tag-auto.yaml",
        AIRFLOW_VAR_CUSTOMER_DQ_RAW_INPUT_YAML = "gs://${var.dataplex_process_bucket_name}/customer-source-configs/dq_customer_gcs_data.yaml",
        AIRFLOW_VAR_CUSTOMER_DX_INFO_INPUT_PATH = "gs://${var.dataplex_process_bucket_name}/customer-source-configs",
        AIRFLOW_VAR_CUSTOMER_DX_INPUT_FILE = "data-product-exchange-tag-manual.yaml",
        AIRFLOW_VAR_DATA_CLASSIFICATION_MAIN_CLASS = "com.google.cloud.dataplex.templates.dataclassification.DataProductClassification",
        AIRFLOW_VAR_DATA_EXCHANGE_MAIN_CLASS = "com.google.cloud.dataplex.templates.datapublication.DataProductPublicationInfo",
        AIRFLOW_VAR_DATA_QUALITY_MAIN_CLASS = "com.google.cloud.dataplex.templates.dataquality.DataProductQuality",
        AIRFLOW_VAR_DPLX_API_END_POINT = "https://dataplex.googleapis.com",
        AIRFLOW_VAR_DQ_BQ_REGION = "${var.location}",
        AIRFLOW_VAR_DQ_DATASET_ID = "central_dq_results",
        AIRFLOW_VAR_DQ_TARGET_SUMMARY_TABLE = "${var.project_id}.central_dq_results.dq_results",
        AIRFLOW_VAR_GCP_CUSTOMER_SA_ACCT = "customer-sa@${var.project_id}.iam.gserviceaccount.com",
        AIRFLOW_VAR_GCP_DG_PROJECT = "${var.project_id}",
        AIRFLOW_VAR_GCP_DG_NUMBER = "${var.project_number}",
        AIRFLOW_VAR_GCP_DW_PROJECT = "${var.datastore_project_id}",
        AIRFLOW_VAR_GCP_MERCHANTS_SA_ACCT = "merchant-sa@${var.project_id}.iam.gserviceaccount.com",
        AIRFLOW_VAR_GCP_PROJECT_REGION = "${var.location}",
        AIRFLOW_VAR_GCP_SUB_NET = "projects/${var.project_id}/regions/${var.location}/subnetworks/default",
        AIRFLOW_VAR_GCP_TRANSACTIONS_CONSUMER_SA_ACCT = "cc-trans-consumer-sa@${var.project_id}.iam.gserviceaccount.com",
        AIRFLOW_VAR_GCP_TRANSACTIONS_SA_ACCT = "cc-trans-sa@${var.project_id}.iam.gserviceaccount.com",
        AIRFLOW_VAR_GCS_DEST_BUCKET = "test",
        AIRFLOW_VAR_GCS_SOURCE_BUCKET = "test",
        AIRFLOW_VAR_GDC_TAG_JAR = "gs://${var.dataplex_process_bucket_name}/common/tagmanager-1.0-SNAPSHOT.jar",
        AIRFLOW_VAR_INPUT_TBL_CC_CUST = "cc_customers_data",
        AIRFLOW_VAR_INPUT_TBL_CUST = "customers_data",
        AIRFLOW_VAR_MERCHANT_DC_INFO_INPUT_PATH = "gs://${var.dataplex_process_bucket_name}/merchant-source-configs/",
        AIRFLOW_VAR_MERCHANT_DC_INPUT_FILE = "data-product-classification-tag-auto.yaml",
        AIRFLOW_VAR_MERCHANT_DP_INFO_INPUT_FILE = "data-product-info-tag-auto.yaml",
        AIRFLOW_VAR_MERCHANT_DP_INFO_INPUT_PATH = "gs://${var.dataplex_process_bucket_name}/merchant-source-configs",
        AIRFLOW_VAR_MERCHANT_DPLX_LAKE_ID = "prod-merchant-source-domain",
        AIRFLOW_VAR_MERCHANT_DPLX_REGION = "${var.location}",
        AIRFLOW_VAR_MERCHANT_DPLX_ZONE_ID = "merchant-data-product-zone",
        AIRFLOW_VAR_MERCHANT_DQ_INFO_INPUT_PATH = "gs://${var.dataplex_process_bucket_name}/merchant-source-configs",
        AIRFLOW_VAR_MERCHANT_DQ_INPUT_FILE = "data-product-quality-tag-auto.yaml",
        AIRFLOW_VAR_MERCHANT_DQ_RAW_INPUT_YAML = "gs://${var.dataplex_process_bucket_name}/merchant-source-configs/dq_merchant_gcs_data.yaml",
        AIRFLOW_VAR_MERCHANT_DX_INPUT_FILE = "data-product-exchange-tag-manual.yaml",
        AIRFLOW_VAR_MERCHANT_DX_INPUT_PATH = "gs://${var.dataplex_process_bucket_name}/merchant-source-configs",
        AIRFLOW_VAR_MERCHANT_ENTITY_LIST_FILE_PATH = "/home/airflow/gcs/data/merchant_data_products/entities.txt",
        AIRFLOW_VAR_MERCHANT_PARTITION_DATE = "2022-05-01",
        AIRFLOW_VAR_PARTITION_DATE = "2022-05-01",
        AIRFLOW_VAR_TABLE_LIST_FILE_PATH = "/home/airflow/gcs/data/tablelist.txt",
        AIRFLOW_VAR_TAG_TEMPLATE_DATA_PRODUCT_CLASSIFICATION = "projects/${var.project_id}/locations/${var.location}/tagTemplates/data_product_classification",
        AIRFLOW_VAR_TAG_TEMPLATE_DATA_PRODUCT_EXCHANGE = "projects/${var.project_id}/locations/${var.location}/tagTemplates/data_product_exchange",
        AIRFLOW_VAR_TAG_TEMPLATE_DATA_PRODUCT_INFO = "projects/${var.project_id}/locations/${var.location}/tagTemplates/data_product_information",
        AIRFLOW_VAR_TAG_TEMPLATE_DATA_PRODUCT_QUALITY = "projects/${var.project_id}/locations/${var.location}/tagTemplates/data_product_quality",
        AIRFLOW_VAR_TRANSACTIONS_DC_INFO_INPUT_PATH = "data-product-classification-tag-auto.yaml",
        AIRFLOW_VAR_TRANSACTIONS_DC_INPUT_FILE = "data-product-classification-tag-auto.yaml",
        AIRFLOW_VAR_TRANSACTIONS_DP_INFO_INPUT_FILE = "data-product-info-tag-auto.yaml",
        AIRFLOW_VAR_TRANSACTIONS_DP_INFO_INPUT_PATH = "gs://${var.dataplex_process_bucket_name}/transactions-source-configs",
        AIRFLOW_VAR_TRANSACTIONS_DPLX_LAKE_ID = "prod-transactions-source-domain",
        AIRFLOW_VAR_TRANSACTIONS_DPLX_REGION = "us-central1",
        AIRFLOW_VAR_TRANSACTIONS_DPLX_ZONE_ID = "transactions-data-product-zone",
        AIRFLOW_VAR_TRANSACTIONS_DQ_INFO_INPUT_FILE = "data-product-quality-tag-auto.yaml",
        AIRFLOW_VAR_TRANSACTIONS_DQ_INFO_INPUT_PATH = "gs://${var.dataplex_process_bucket_name}/transactions-source-configs",
        AIRFLOW_VAR_TRANSACTIONS_DQ_INPUT_FILE = "data-product-quality-tag-auto.yaml",
        AIRFLOW_VAR_TRANSACTIONS_DQ_RAW_INPUT_YAML = "gs://${var.dataplex_process_bucket_name}/transactions-source-configs/dq_transactions_gcs_data.yaml",
        AIRFLOW_VAR_TRANSACTIONS_DX_INFO_INPUT_PATH = "gs://${var.dataplex_process_bucket_name}/transactions-source-configs",
        AIRFLOW_VAR_TRANSACTIONS_DX_INPUT_FILE = "data-product-exchange-tag-manual.yaml",
        AIRFLOW_VAR_TRANSACTIONS_DX_INPUT_PATH = "gs://${var.dataplex_process_bucket_name}/transactions-source-configs/",
        AIRFLOW_VAR_TRANSACTIONS_ENTITY_LIST_FILE_PATH = "/home/airflow/gcs/data/transactions_data_products/entities.txt",
        AIRFLOW_VAR_TRANSACTIONS_PARTITION_DATE = "2022-05-01",
        AIRFLOW_VAR_CUSTOMER_DQ_DP_INPUT_YAML="gs://${var.dataplex_process_bucket_name}/customer-source-configs/dq_customer_data_product.yaml",
        AIRFLOW_VAR_TOKCUSTOMER_DQ_DP_INPUT_YAML="gs://${var.dataplex_process_bucket_name}/customer-source-configs/dq_tokenized_customer_data_product.yaml",
        AIRFLOW_VAR_MERCHANT_DQ_DP_INPUT_YAML="gs://${var.dataplex_process_bucket_name}/merchant-source-configs/dq_merchant_data_product.yaml",
        AIRFLOW_VAR_TRANS_SRC_DQ_DP_INPUT_YAML="gs://${var.dataplex_process_bucket_name}/transactions-source-configs/dq_transactions_data_product.yaml",
        AIRFLOW_VAR_TRANS_CON_DQ_DP_INPUT_YAML="gs://${var.dataplex_process_bucket_name}/transactions-consumer-configs/dq_cc_analytics_data_product.yaml",

      }
    }

    # this is designed to be the smallest cheapest Composer for demo purposes
    workloads_config {
      scheduler {
        cpu        = 4
        memory_gb  = 10
        storage_gb = 10
        count      = 1
      }
      web_server {
        cpu        = 0.5
        memory_gb  = 1
        storage_gb = 1
      }
      worker {
        cpu        = 2
        memory_gb  = 10
        storage_gb = 10
        min_count  = 1
        max_count  = 4
      }
    }

    environment_size = "ENVIRONMENT_SIZE_SMALL"

    node_config {
      network         = var.network_id
      subnetwork      = google_compute_subnetwork.composer_subnet.id
      service_account = google_service_account.composer_service_account.name
    }
  }

  depends_on = [
    google_project_iam_member.cloudcomposer_account_service_agent_v2_ext,
    google_project_iam_member.cloudcomposer_account_service_agent,
    google_compute_subnetwork.composer_subnet,
    google_service_account.composer_service_account,
    google_project_iam_member.composer_service_account_worker_role,
 ##   google_project_iam_member.composer_service_account_bq_admin_role
  ]

  timeouts {
    create = "90m"
  }
}


resource "null_resource" "dag_setup" {
  provisioner "local-exec" {
    command = <<-EOT
    export airflow_dag_folder=$(gcloud composer environments describe ${var.project_id}-composer --location="us-central1" | grep dagGcsPrefix | awk  '{print $2}')
    export airflow_data_folder=$(gcloud composer environments describe ${var.project_id}-composer --location="us-central1" | grep dagGcsPrefix | awk  '{print $2}' | sed -e 's/dags/data/')
    gsutil mv gs://${local._dataplex_process_bucket_name}/dags/* $airflow_dag_folder
    gsutil mv gs://${local._dataplex_process_bucket_name}/airflow_data/* $airflow_data_folder/
    EOT
    }
    depends_on = [
               google_composer_environment.composer_env]

  }
