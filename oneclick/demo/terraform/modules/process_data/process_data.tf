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



variable "command_string" {
    type = string
    default = <<-EOT
echo gcloud beta dataproc batches submit spark
   --project=%s 
    --region=%s 
    --jars=\"file:///usr/lib/spark/external/spark-avro.jar,gs://%s/dataproc-templates-1.0-SNAPSHOT.jar\"
    --labels=job_type=dataproc_template 
    --deps-bucket=%s 
    --files=%s 
    --class=com.google.cloud.dataproc.templates.main.DataProcTemplate 
    --template=DATAPLEXGCSTOBQ  
    --templateProperty=project.id=%s 
    --templateProperty=dataplex.gcs.bq.target.dataset=%s 
    --templateProperty=gcs.bigquery.temp.bucket.name=gs://%s 
    --templateProperty=dataplex.gcs.bq.save.mode=\"append\" 
    --templateProperty=dataplex.gcs.bq.incremental.partition.copy=\"yes\" 
    --dataplexEntity=\"projects/%s/locations/%s/lakes/%s/zones/%s/entities/cc_customers_data\" 
    --partitionField=\"ingest_date\" 
    --partitionType="DAY" 
    --customSqlGcsPath="gs://%s/customercustom.sql"
EOT
}

resource "null_resource" "copy_asset" {
  provisioner "local-exec" {
    command = format(var.command_string, var.project_id,
                var.location,
                var.dataplex_process_bucket_name,
                var.dataplex_process_bucket_name,
                var.project_id,
                "prod_customer_refined_data",  
                var.dataplex_process_bucket_name,
                var.project_id,
                var.location,
                "prod-customer-source-domain",
                "customer-raw-zone",
                customercustom.sql
                )
  }
}






