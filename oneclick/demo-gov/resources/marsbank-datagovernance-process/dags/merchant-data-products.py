import datetime
from airflow import models
from airflow.operators import bash
from airflow.operators import email
from airflow.providers.google.cloud.operators import bigquery
from airflow.providers.google.cloud.transfers import bigquery_to_gcs
from airflow.utils import trigger_rule
from airflow.models.baseoperator import chain


REGION = "us-central1"
bq_location = 'US'
project_id_dw = models.Variable.get('gcp_dw_project')
project_id_dg = models.Variable.get('gcp_dg_project')
IMPERSONATION_CHAIN = models.Variable.get('gcp_merchants_sa_acct')
#input_tbl_cust= models.Variable.get('input_tbl_merch')
#input_tbl_cc_cust= models.Variable.get('input_tbl_cc_cust')
partition_date = models.Variable.get('merchant_partition_date')


CREATE_MERCHANT_CORE_DATA_PRODUCT_TABLE = f"""
CREATE TABLE IF NOT EXISTS `{project_id_dw}.prod_merchants_data_product.core_merchants`
(
  merchant_id STRING,
  merchant_name STRING,
  mcc INT64,
  email STRING,
  street STRING,
  city STRING,
  state STRING,
  country STRING,
  zip STRING,
  latitude FLOAT64,
  longitude FLOAT64,
  owner_id STRING,
  owner_name STRING,
  terminal_ids STRING,
  Description STRING,
  Market_Segment STRING,
  Industry_Code_Description STRING,
  Industry_Code STRING,
  ingest_date DATE
);
"""
INSERT_MERCHANT_CORE_DATA_PRODUCT_TABLE = f"""
INSERT INTO  `{project_id_dw}.prod_merchants_data_product.core_merchants`
SELECT
merchant_id ,
  merchant_name ,
  merchants.mcc as mcc ,
  email ,
  street ,
  CASE
    WHEN merchants.city is null THEN zip.city
    ELSE merchants.city 
    END
    AS city ,
  CASE
    WHEN merchants.state is null THEN zip.state_name
    ELSE merchants.state 
    END
    AS state,
   CASE
    WHEN merchants.country is null THEN "USA"
    ELSE merchants.country 
    END
    AS  country ,
   CASE
    WHEN merchants.zip is null THEN zip.zip_code
    ELSE merchants.zip 
    END
    AS zip ,
  latitude ,
  longitude ,
  owner_id ,
  owner_name ,
  terminal_ids ,
  description ,
  market_Segment ,
  Industry_Code_Descritption as industry_Code_description ,
  industry_Code ,
  merchants.ingest_date  as ingest_date

FROM
`{project_id_dw}.prod_merchants_refined_data.merchants_data` as merchants,
  `bigquery-public-data.geo_us_boundaries.zip_codes` AS zip
left outer join 
 `{project_id_dw}.prod_merchants_ref_data.mcc_codes` mcc
 on 
 merchants.mcc=mcc.mcc
 WHERE
  ST_WITHIN(ST_GEOGPOINT(merchants.latitude,
      merchants.longitude ),
    zip.zip_code_geom)
    AND 
    merchants.ingest_date='{partition_date}';
"""


yesterday = datetime.datetime.combine(
    datetime.datetime.today() - datetime.timedelta(1),
    datetime.datetime.min.time())

# [START composer_notify_failure]
default_dag_args = {
    'start_date': yesterday,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 0,
    'retry_delay': datetime.timedelta(minutes=1),
    'project_id': project_id_dg,
    'region': REGION,

}

with models.DAG(
        'etl-merchant-process',
        catchup=False,
        schedule_interval=None,
        default_args=default_dag_args) as dag:

    bq_create_merchant_prod_tbl = bigquery.BigQueryInsertJobOperator(
        task_id="bq_create_merchant_prod_tbl",
        impersonation_chain=IMPERSONATION_CHAIN,
        configuration={
            "query": {
                "query": CREATE_MERCHANT_CORE_DATA_PRODUCT_TABLE,
                "useLegacySql": False
            }
        }
    )

    bq_insert_merchant_prod_tbl = bigquery.BigQueryInsertJobOperator(
        task_id="bq_insert_merchant_prod_tbl",
        impersonation_chain=IMPERSONATION_CHAIN,
        configuration={
            "query": {
                "query": INSERT_MERCHANT_CORE_DATA_PRODUCT_TABLE,
                "useLegacySql": False
            }
        }
    )
    
    chain(bq_create_merchant_prod_tbl>>bq_insert_merchant_prod_tbl)