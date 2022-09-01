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
  service_account_id ="projects/${var.project_id}/serviceAccounts/${var.project_id}-admin-sa@${var.project_id}.iam.gserviceaccount.com"
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

resource "google_composer_environment" "composer_env" {
  project  = var.project_id
  name     = "datamesh-enablement-demo-composer-2"
  region   = var.location

  config {

    software_config {
      image_version = "composer-2.0.0-airflow-2.1.4"
      #"composer-2.0.7-airflow-2.2.3"

      env_variables = {
        
        cust_entity_list_file_path = "/home/airflow/gcs/data/customer_data_products/entities.txt",
        customer_dc_info_input_path = "${var.dataplex_process_bucket_name}/customer-source-configs",
        customer_dc_input_file = "data-product-classification-tag-auto.yaml",
        customer_dp_info_input_file = "data-product-info-tag-auto.yaml",
        customer_dp_info_input_path = "${var.dataplex_process_bucket_name}/customer-source-configs",
        customer_dplx_lake_id = "prod-customer-source-domain",
        customer_dplx_region = "${var.location}",
        customer_dplx_zone_id = "customer-data-product-zone",
        customer_dq_info_input_path = "${var.dataplex_process_bucket_name}/customer-source-configs",
        customer_dq_input_file = "data-product-quality-tag-auto.yaml",
        customer_dq_raw_input_yaml = "${var.dataplex_process_bucket_name}/customer-source-configs/dq_customer_gcs_data.yaml",
        customer_dx_info_input_path = "${var.dataplex_process_bucket_name}/customer-source-configs",
        customer_dx_input_file = "data-product-exchange-tag-manual.yaml",
        data_classification_main_class = "com.google.cloud.dataplex.templates.dataclassification.DataProductClassification",
        data_exchange_main_class = "com.google.cloud.dataplex.templates.datapublication.DataProductPublicationInfo",
        data_quality_main_class = "com.google.cloud.dataplex.templates.dataquality.DataProductQuality",
        dplx_api_end_point = "https://dataplex.googleapis.com",
        dq_bq_region = "US",
        dq_dataset_id = "prod_dq_check_ds",
        dq_target_summary_table = "${var.prefix}-datagovernance.prod_dq_check_ds.dq_results",
        #gcp_customer_sa_acct = "customer-sa@${var.project_id}.iam.gserviceaccount.com",
        gcp_dg_project = "${var.project_id}",
        gcp_dw_project = "${var.datastore_project_id",
        #gcp_merchants_sa_acct = "merchant-sa@${var.project_id}.iam.gserviceaccount.com",
        gcp_project_region = "${var.location}",
        gcp_sub_net = "projects/${var.project_id}/regions/${var.location}/subnetworks/${var.prefix}-misc-subnet",
        #gcp_transactions_consumer_sa_acct = "cc-trans-consumer-sa@${var.project_id}.iam.gserviceaccount.com",
        #gcp_transactions_sa_acct = "cc-trans-sa@${var.project_id}.iam.gserviceaccount.com",
        gcs_dest_bucket = "test",
        gcs_source_bucket = "test",
        gdc_tag_jar = "${var.dataplex_process_bucket_name}/common/tagmanager-1.0-SNAPSHOT.jar",
        input_tbl_cc_cust = "cc_customers_data",
        input_tbl_cust = "customers_data",
        merchant_dc_info_input_path = "${var.dataplex_process_bucket_name}/merchant-source-configs/",
        merchant_dc_input_file = "data-product-classification-tag-auto.yaml",
        merchant_dp_info_input_file = "data-product-info-tag-auto.yaml",
        merchant_dp_info_input_path = "${var.dataplex_process_bucket_name}/merchant-source-configs",
        merchant_dplx_lake_id = "prod-merchant-source-domain",
        merchant_dplx_region = "${var.location}",
        merchant_dplx_zone_id = "merchant-data-product-zone",
        merchant_dq_info_input_path = "${var.dataplex_process_bucket_name}/merchant-source-configs",
        merchant_dq_input_file = "data-product-quality-tag-auto.yaml",
        merchant_dq_raw_input_yaml = "${var.dataplex_process_bucket_name}/merchant-source-configs/dq_merchant_gcs_data.yaml",
        merchant_dx_input_file = "data-product-exchange-tag-manual.yaml",
        merchant_dx_input_path = "${var.dataplex_process_bucket_name}/merchant-source-configs",
        merchant_entity_list_file_path = "/home/airflow/gcs/data/merchant_data_products/entities.txt",
        merchant_partition_date = "2022-05-01",
        partition_date = "2022-05-01",
        table_list_file_path = "/home/airflow/gcs/data/tablelist.txt",
        tag_template_data_product_classification = "projects/${var.project_id}/locations/${var.location}/tagTemplates/data_product_classification",
        tag_template_data_product_exchange = "projects/${var.project_id}/locations/${var.location}/tagTemplates/data_product_exchange",
        tag_template_data_product_info = "projects/${var.project_id}/locations/${var.location}tagTemplates/data_product_information",
        tag_template_data_product_quality = "projects/${var.project_id}/locations/${var.location}/tagTemplates/data_product_quality",
        transactions_dc_info_input_path = "data-product-classification-tag-auto.yaml",
        transactions_dc_input_file = "data-product-classification-tag-auto.yaml",
        transactions_dp_info_input_file = "data-product-info-tag-auto.yaml",
        transactions_dp_info_input_path = "${var.dataplex_process_bucket_name}/transactions-source-configs",
        transactions_dplx_lake_id = "prod-transactions-source-domain",
        transactions_dplx_region = "us-central1",
        transactions_dplx_zone_id = "transactions-data-product-zone",
        transactions_dq_info_input_file = "data-product-quality-tag-auto.yaml",
        transactions_dq_info_input_path = "${var.dataplex_process_bucket_name}/transactions-source-configs",
        transactions_dq_input_file = "data-product-quality-tag-auto.yaml",
        transactions_dq_raw_input_yaml = "${var.dataplex_process_bucket_name}/transactions-source-configs/dq_transactions_gcs_data.yaml",
        transactions_dx_info_input_path = "${var.dataplex_process_bucket_name}/transactions-source-configs",
        transactions_dx_input_file = "data-product-exchange-tag-manual.yaml",
        transactions_dx_input_path = "${var.dataplex_process_bucket_name}/transactions-source-configs/",
        transactions_entity_list_file_path = "/home/airflow/gcs/data/transactions_data_products/entities.txt",
        transactions_partition_date = "2022-05-01"
      }
    }

    # this is designed to be the smallest cheapest Composer for demo purposes
    workloads_config {
      scheduler {
        cpu        = 1
        memory_gb  = 1
        storage_gb = 1
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