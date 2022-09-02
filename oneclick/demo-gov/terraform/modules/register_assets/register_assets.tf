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
    command = format("gcloud dataplex assets create %s --csv-header-rows=1 --csv-delimiter=\"|\" --location=%s --lake=%s --zone=%s --resource-type=STORAGE_BUCKET --resource-name=%s --discovery-enabled --display-name=\"%s\"", 
                     element(split("/", each.key), 0),
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

  depends_on = [null_resource.create_zones_nolabels]
}


resource "null_resource" "register_gcs_assets2" {
 for_each = {
    "customer-raw-data/Customer Raw Data/customer-raw-zone/prod-customer-source-domain" : var.customers_bucket_name
    "transactions-curated-data/Transactions Curated Data/transactions-curated-zone/prod-transactions-source-domain" : var.transactions_curated_bucket_name,
    "merchant-curated-data/Merchant Curated Data/merchant-curated-zone/prod-merchant-source-domain" : var.merchants_curated_bucket_name,
    "customer-curated-data/Customer Curated Data/customer-curated-zone/prod-customer-source-domain" : var.customers_curated_bucket_name
  }
  provisioner "local-exec" {
    command = format("gcloud dataplex assets create %s --csv-header-rows=1 --csv-delimiter=\"|\" --location=%s --lake=%s --zone=%s --resource-type=STORAGE_BUCKET --resource-name=%s --discovery-enabled --display-name=\"%s\"", 
                     element(split("/", each.key), 0),
                     var.location,
                     element(split("/", each.key), 3),
                     element(split("/", each.key), 2),
                     "projects/${var.datastore_project_id}/buckets/${each.value}",
                     element(split("/", each.key), 1),
                     )
  }

  depends_on  = [time_sleep.sleep_after_assets]

}
