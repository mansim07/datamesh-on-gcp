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


/*

gs://jayoleary_bankofmars_retail_credit_cards_trasactions_data/ref_data/card_read_type/
gs://jayoleary_bankofmars_retail_credit_cards_trasactions_data/ref_data/card_type_facts/
gs://jayoleary_bankofmars_retail_credit_cards_trasactions_data/ref_data/currency/
gs://jayoleary_bankofmars_retail_credit_cards_trasactions_data/ref_data/events_type/
gs://jayoleary_bankofmars_retail_credit_cards_trasactions_data/ref_data/origination_code/
gs://jayoleary_bankofmars_retail_credit_cards_trasactions_data/ref_data/payment_methods/
gs://jayoleary_bankofmars_retail_credit_cards_trasactions_data/ref_data/signature/
gs://jayoleary_bankofmars_retail_credit_cards_trasactions_data/ref_data/swiped_code/
gs://jayoleary_bankofmars_retail_credit_cards_trasactions_data/ref_data/trans_type/

gs://jayoleary_bankofmars_retail_credit_cards_trasactions_data/auth_data/date=2020-10-10/trans_data.csv
gs://jayoleary_bankofmars_retail_merchants_data/mcc_codes/date=2020-10-10/mcc_codes.csv
​​gs://jayoleary_bankofmars_retail_merchants_data/merchants_data/date=2020-10-10/merchants.csv
gs://jayolearbankofmars_retail_customers_source_data/cc_customers_data/dt=2020-10-10/cc_customer.csv
gs://jayolearbankofmars_retail_customers_source_data/customers_data/dt=2020-10-10/customer.csv

gcloud dataplex assets create inventory \
--location=$LOCATION \
--lake=$LAKE_NM \
--zone=product-zone \
--resource-type=STORAGE_BUCKET \
--resource-name=projects/$PROJECT_ID/buckets/$BUCKET_INVENTORY_NM \
--discovery-enabled

gcloud dataplex assets create customer-events \
--location=$LOCATION \
--lake=$LAKE_NM \
--zone=customer-zone \
--resource-type=BIGQUERY_DATASET \
--resource-name=projects/$PROJECT_ID/datasets/$BQ_EVENT_DATASET_NM \
--discovery-enabled
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

resource "null_resource" "register_gcs_assets3" {
 for_each = {
    "transactions-ref-raw-data/Transactions Ref Raw Data/transactions-raw-zone/prod-transactions-source-domain" : var.transactions_ref_bucket_name,
    "transactions-raw-data/Transactions Raw Data/transactions-raw-zone/prod-transactions-source-domain" : var.transactions_bucket_name,
    "merchant-raw-data/Merchant Raw Data/merchant-raw-zone/prod-merchant-source-domain" : var.merchants_bucket_name,
    "customer-raw-data/Customer Raw Data/customer-raw-zone/prod-customer-source-domain" : var.customers_bucket_name
  }
  provisioner "local-exec" {
    command = format("gcloud dataplex assets create %s --location=%s --lake=%s --zone=%s --resource-type=STORAGE_BUCKET --resource-name=%s --discovery-enabled --display-name=\"%s\"", 
                     element(split("/", each.key), 0),
                     var.location,
                     element(split("/", each.key), 3),
                     element(split("/", each.key), 2),
                     "projects/${var.project_id}/buckets/${each.value}",
                     element(split("/", each.key), 1),
                     )
  }
}

