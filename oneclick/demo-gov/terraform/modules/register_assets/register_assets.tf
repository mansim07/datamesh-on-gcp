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
variable "location" {}
variable "lake_name" {}
variable "customers_bucket_name" {}
variable "merchants_bucket_name" {}
variable "transactions_bucket_name" {}
variable "transactions_ref_bucket_name" {}
variable "customers_curated_bucket_name" {}
variable "merchants_curated_bucket_name" {}
variable "transactions_curated_bucket_name" {}
variable "datastore_project_id" {}

resource "null_resource" "register_gcs_assets1" {
 for_each = {
    "transactions-ref-raw-data/Transactions Ref Raw Data/transactions-raw-zone/prod-transactions-source-domain" : var.transactions_ref_bucket_name,
    "transactions-raw-data/Transactions Raw Data/transactions-raw-zone/prod-transactions-source-domain" : var.transactions_bucket_name,
    "merchant-raw-data/Merchant Raw Data/merchant-raw-zone/prod-merchant-source-domain" : var.merchants_bucket_name,
  }
  provisioner "local-exec" {
    command = format("gcloud dataplex assets --project=%s create %s --csv-header-rows=1 --csv-delimiter=\"|\" --location=%s --lake=%s --zone=%s --resource-type=STORAGE_BUCKET --resource-name=%s --discovery-enabled --display-name=\"%s\"", 
                     var.project_id,element(split("/", each.key), 0),
                     var.location,
                     element(split("/", each.key), 3),
                     element(split("/", each.key), 2),
                     "projects/${var.datastore_project_id}/buckets/${each.value}",
                     element(split("/", each.key), 1),
                     )
  }
}

#sometimes we get API rate limit errors for dataplex; add wait until this is resolved.
resource "time_sleep" "sleep_after_assets" {
  create_duration = "60s"

  depends_on = [null_resource.register_gcs_assets1]
}

resource "null_resource" "register_gcs_assets2" {
 for_each = {
    "customer-raw-data/Customer Raw Data/customer-raw-zone/prod-customer-source-domain" : var.customers_bucket_name
    "transactions-curated-data/Transactions Curated Data/transactions-curated-zone/prod-transactions-source-domain" : var.transactions_curated_bucket_name,
    "merchant-curated-data/Merchant Curated Data/merchant-curated-zone/prod-merchant-source-domain" : var.merchants_curated_bucket_name,
    "customer-curated-data/Customer Curated Data/customer-curated-zone/prod-customer-source-domain" : var.customers_curated_bucket_name
  }
  provisioner "local-exec" {
    command = format("gcloud dataplex assets --project=%s create %s --csv-header-rows=1 --csv-delimiter=\"|\" --location=%s --lake=%s --zone=%s --resource-type=STORAGE_BUCKET --resource-name=%s --discovery-enabled --display-name=\"%s\"", 
                     var.project_id,element(split("/", each.key), 0),
                     var.location,
                     element(split("/", each.key), 3),
                     element(split("/", each.key), 2),
                     "projects/${var.datastore_project_id}/buckets/${each.value}",
                     element(split("/", each.key), 1),
                     )
  }

  depends_on  = [time_sleep.sleep_after_assets]

}


#sometimes we get API rate limit errors for dataplex; add wait until this is resolved.
resource "time_sleep" "sleep_after_gcs_assets2" {
  create_duration = "60s"

  depends_on = [null_resource.register_gcs_assets2]
}


resource "null_resource" "register_bq_assets1" {
 for_each = {
    "customer-data-product/Customer Data Product/customer-data-product-zone/prod-customer-source-domain" : "customer_data_product",
    "customer-data-product-reference/Customer Reference Data Product/customer-data-product-zone/prod-customer-source-domain" : "customer_ref_data" ,
     "customer-refined-data/Customer Refined Data/customer-curated-zone/prod-customer-source-domain" : "customer_refined_data" ,
    "merchant-refined-data/Merchant Refined Data/merchant-curated-zone/prod-merchant-source-domain" : "merchants_refined_data"
    
  }
  provisioner "local-exec" {
    command = format("gcloud dataplex assets --project=%s create %s --location=%s --lake=%s --zone=%s --resource-type=BIGQUERY_DATASET --resource-name=%s --discovery-enabled --display-name=\"%s\"", 
                     var.project_id,element(split("/", each.key), 0),
                     var.location,
                     element(split("/", each.key), 3),
                     element(split("/", each.key), 2),
                     "projects/${var.datastore_project_id}/datasets/${each.value}",
                     element(split("/", each.key), 1),
                     )
  }

  depends_on  = [time_sleep.sleep_after_gcs_assets2]

}

resource "null_resource" "register_bq_assets2" {
 for_each = {
    "merchant-data-products/Merchant Data Product/merchant-data-product-zone/prod-merchant-source-domain" : "merchants_data_product",
    "merchant-ref-product/Merchant Data Product Reference/merchant-data-product-zone/prod-merchant-source-domain" : "merchants_ref_data",
    "transactions-data-product/Transactions Data Product/transactions-data-product-zone/prod-transactions-source-domain" : "auth_data_product",
    "transaction-ref-product/Transactions Data Product Reference/transactions-data-product-zone/prod-transactions-source-domain" : "auth_ref_data",
     "cc-analytics-data-product/CCA Data Product/data-product-zone/prod-transactions-consumer-domain" : "cc_analytics_data_product "
  }
  provisioner "local-exec" {
    command = format("gcloud dataplex assets --project=%s create %s --location=%s --lake=%s --zone=%s --resource-type=BIGQUERY_DATASET --resource-name=%s --discovery-enabled --display-name=\"%s\"", 
                     var.project_id,element(split("/", each.key), 0),
                     var.location,
                     element(split("/", each.key), 3),
                     element(split("/", each.key), 2),
                     "projects/${var.datastore_project_id}/datasets/${each.value}",
                     element(split("/", each.key), 1),
                     )
  }

  depends_on  = [null_resource.register_gcs_assets2]

}

#sometimes we get API rate limit errors for dataplex; add wait until this is resolved.
resource "time_sleep" "sleep_after_bq_assets2" {
  create_duration = "60s"

  depends_on = [null_resource.register_bq_assets2]
}



resource "null_resource" "register_bq_assets3" {
 for_each = {
    
    "dlp-reports/DLP Reports/operations-data-product-zone/central-operations-domain" : "central_dlp_data" ,
    "dq-reports/DQ Reports/operations-data-product-zone/central-operations-domain" : "central_dq_results" ,
    "audit-data/Audit Data/operations-data-product-zone/central-operations-domain" : "central_audit_data" ,
     "enterprise-reference-data/Enterprise Reference Data/operations-data-product-zone/central-operations-domain" : "enterprise_reference_data" ,

    
  }
  provisioner "local-exec" {
    command = format("gcloud dataplex assets --project=%s create %s --location=%s --lake=%s --zone=%s --resource-type=BIGQUERY_DATASET --resource-name=%s --discovery-enabled --display-name=\"%s\"", 
                     var.project_id,element(split("/", each.key), 0),
                     var.location,
                     element(split("/", each.key), 3),
                     element(split("/", each.key), 2),
                     "projects/${var.project_id}/datasets/${each.value}",
                     element(split("/", each.key), 1),
                     )
  }

  depends_on  = [time_sleep.sleep_after_bq_assets2]

}



resource "null_resource" "register_gcs_assets3" {
 for_each = {
      "common-utilities/COMMON UTILITIES/common-utilities/central-operations-domain" : format("%s_dataplex_process" ,var.project_id)
  }
  provisioner "local-exec" {
    command = format("gcloud dataplex assets --project=%s create %s --location=%s --lake=%s --zone=%s --resource-type=STORAGE_BUCKET --resource-name=%s --no-discovery-enabled --display-name=\"%s\"", 
                     var.project_id,element(split("/", each.key), 0),
                     var.location,
                     element(split("/", each.key), 3),
                     element(split("/", each.key), 2),
                     "projects/${var.project_id}/buckets/${each.value}",
                     element(split("/", each.key), 1),
                     )
  }

  depends_on  = [null_resource.register_bq_assets3]

}