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
variable "date_partition" {}
variable "tmpdir" {}
variable "customers_bucket_name" {}
variable "merchants_bucket_name" {}
variable "transactions_bucket_name" {}
variable "data_gen_git_repo" {}
variable "transactions_ref_bucket_name" {}
variable "dataplex_process_bucket_name" {}


####################################################################################
# Generate Sample Data
####################################################################################
#retrieve data generator

resource "null_resource" "git_clone_datagen" {
  provisioner "local-exec" {
    command = "git clone --branch one-click-deploy ${var.data_gen_git_repo}"
  }
  provisioner "local-exec" {
    command = <<-EOT
      rm -rf ./datamesh-datagenerator
      rm /tmp/data/*
    EOT
    when    = destroy
  }
}


#run data creation process
resource "null_resource" "run_datagen" {
  provisioner "local-exec" {
    command = <<-EOT
      cd ./datamesh-datagenerator
      ./oneclick_deploy.sh ${var.date_partition} ${var.tmpdir} ${var.project_id} ${var.customers_bucket_name} ${var.merchants_bucket_name} ${var.transactions_bucket_name}
    EOT
    }
    depends_on = [null_resource.git_clone_datagen]

  }

####################################################################################
# Create GCS Buckets
####################################################################################

resource "google_storage_bucket" "storage_buckets" {
  project                     = var.project_id
  for_each = toset([
    var.customers_bucket_name,
    var.merchants_bucket_name,
    var.transactions_bucket_name,
    var.transactions_ref_bucket_name,
    var.dataplex_process_bucket_name])
  name                        = each.key
  location                    = var.location
  force_destroy               = true
  uniform_bucket_level_access = true

  depends_on = [null_resource.run_datagen]

}

####################################################################################
# Create Customer GCS Objects
####################################################################################

resource "google_storage_bucket_object" "gcs_customers_objects" {
  for_each = {
    format("%s/customer.csv", var.tmpdir) : format("customers_data/dt=%s/customer.csv", var.date_partition),
    format("%s/cc_customer.csv", var.tmpdir) : format("cc_customers_data/dt=%s/cc_customer.csv", var.date_partition)
  }
  name        = each.value
  source      = each.key
  bucket = var.customers_bucket_name
  depends_on = [google_storage_bucket.storage_buckets]
}

####################################################################################
# Create Merchants GCS Objects
####################################################################################

resource "google_storage_bucket_object" "gcs_merchants_objects" {
  for_each = {
    format("%s/merchants.csv", var.tmpdir) : format("merchants_data/dt=%s/merchants.csv", var.date_partition),
    "./datamesh-datagenerator/merchant_data/data/ref_data/mcc_codes.csv" : format("merchants_data/dt=%s/mcc_codes/mcc_codes.csv", var.date_partition),
  }
  name        = each.value
  source      = each.key
  bucket = var.merchants_bucket_name
  depends_on = [google_storage_bucket.storage_buckets]
}

####################################################################################
# Create Transactions GCS Objects
####################################################################################

resource "google_storage_bucket_object" "gcs_transaction_objects" {
  for_each = {
    format("%s/trans_data.csv", var.tmpdir) : format("auth_data/dt=%s/trans_data.csv", var.date_partition)
  }
  name        = each.value
  source      = each.key
  bucket = var.transactions_bucket_name
  depends_on = [google_storage_bucket.storage_buckets]
}

resource "google_storage_bucket_object" "gcs_transaction_refdata_objects" {
  for_each = toset([
    "signature",
    "card_type_facts",
    "payment_methods",
    "events_type",
    "currency",
    "swiped_code",
    "origination_code",
    "trans_type",
    "card_read_type"
  ])
  name        = format("ref_data/%s/%s.csv", each.key, each.key)
  source      = format("./datamesh-datagenerator/transaction_data/data/ref_data/%s.csv", each.key)
  bucket      = var.transactions_ref_bucket_name
  depends_on  = [google_storage_bucket.storage_buckets]
}

####################################################################################
# Create Process GCS Objects
####################################################################################

resource "google_storage_bucket_object" "gcs_dataplex_process_objects" {
  for_each = {
    "../resources/dataproc-templates-1.0-SNAPSHOT.jar" : "dataproc-templates-1.0-SNAPSHOT.jar",
    "../resources/log4j-spark-driver-template.properties" : "log4j-spark-driver-template.properties",
    "../resources/customercustom.sql" : "customercustom.sql"
  }
  name        = each.value
  source      = each.key
  bucket = var.dataplex_process_bucket_name
  depends_on = [google_storage_bucket.storage_buckets]
}

####################################################################################
# Create BigQuery Datasets
####################################################################################

resource "google_bigquery_dataset" "bigquery_datasets" {
  for_each = toset([ 
    "raw_data",
    "merchants_reference_data",
    "source_data",
    "lookup_data"
  ])
  project                     = var.project_id
  dataset_id                  = each.key
  friendly_name               = each.key
  description                 = "${each.key} Dataset for Dataplex Demo"
  location                    = var.location
  delete_contents_on_destroy  = true
}

####################################################################################
# Create BigQuery Tables
####################################################################################

resource "random_integer" "jobid" {
  min     = 1000
  max     = 1999
}

resource "google_bigquery_job" "job" {
  for_each = {
    "raw_data.customer_demographics" : format("gs://%s/customers_data/dt=%s/customer.csv", var.customers_bucket_name, var.date_partition),
    "raw_data.cc_customer_data" : format("gs://%s/cc_customers_data/dt=%s/cc_customer.csv", var.customers_bucket_name, var.date_partition),
    "raw_data.core_merchants" : format("gs://%s/merchants_data/dt=%s/merchants.csv", var.merchants_bucket_name, var.date_partition),
    "merchants_reference_data.mcc_code" : format("gs://%s/merchants_data/dt=%s/mcc_codes/mcc_codes.csv", var.merchants_bucket_name, var.date_partition),
    "source_data.auth_table" : format("gs://%s/auth_data/dt=%s/trans_data.csv", var.transactions_bucket_name, var.date_partition),
    "lookup_data.signature" : format("gs://%s/ref_data/signature/signature.csv", var.transactions_ref_bucket_name),
    "lookup_data.card_type_facts" : format("gs://%s/ref_data/card_type_facts/card_type_facts.csv", var.transactions_ref_bucket_name),
    "lookup_data.payment_methods" : format("gs://%s/ref_data/payment_methods/payment_methods.csv", var.transactions_ref_bucket_name),
    "lookup_data.events_type" : format("gs://%s/ref_data/events_type/events_type.csv", var.transactions_ref_bucket_name),
    "lookup_data.currency" : format("gs://%s/ref_data/currency/currency.csv", var.transactions_ref_bucket_name),
    "lookup_data.swiped_code" : format("gs://%s/ref_data/swiped_code/swiped_code.csv", var.transactions_ref_bucket_name),
    "lookup_data.origination_code" : format("gs://%s/ref_data/origination_code/origination_code.csv", var.transactions_ref_bucket_name),
    "lookup_data.trans_type" : format("gs://%s/ref_data/trans_type/trans_type.csv", var.transactions_ref_bucket_name),
    "lookup_data.card_read_type" : format("gs://%s/ref_data/card_read_type/card_read_type.csv", var.transactions_ref_bucket_name)
  }
  job_id     = format("job_load_%s_${random_integer.jobid.result}", element(split(".", each.key), 1))
  project    = var.project_id
  location   = var.location
  #labels = {
  #  "my_job" ="load"
  #}

  load {
    source_uris = [
      each.value
    ]

    destination_table {
      project_id = var.project_id
      dataset_id = element(split(".", each.key), 0)
      table_id   = element(split(".", each.key), 1)
    }

    skip_leading_rows = 1
    schema_update_options = ["ALLOW_FIELD_RELAXATION", "ALLOW_FIELD_ADDITION"]

    write_disposition = "WRITE_APPEND"
    autodetect = true
    }

    depends_on  = [google_storage_bucket_object.gcs_transaction_refdata_objects,
                   google_storage_bucket_object.gcs_transaction_objects,
                   google_storage_bucket_object.gcs_customers_objects,
                   google_storage_bucket_object.gcs_merchants_objects,
                   google_bigquery_dataset.bigquery_datasets
                  ]
  }

  