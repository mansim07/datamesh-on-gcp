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
IMPERSONATION_CHAIN = models.Variable.get('gcp_customer_sa_acct')
input_tbl_cust= models.Variable.get('input_tbl_cust')
input_tbl_cc_cust= models.Variable.get('input_tbl_cc_cust')
partition_date = models.Variable.get('partition_date')


CUST_REF_DATA_TABLE = f"""
CREATE TABLE IF NOT EXISTS `{project_id_dw}.customer_refined_data.{input_tbl_cust}`
(
  client_id STRING,
  ssn STRING,
  first_name STRING,
  last_name STRING,
  gender STRING,
  street STRING,
  city STRING,
  state STRING,
  zip INT64,
  latitude FLOAT64,
  longitude FLOAT64,
  city_pop INT64,
  job STRING,
  dob STRING,
  email STRING,
  phonenum STRING,
  profile STRING,
  dt STRING,
  ingest_date DATE
)
PARTITION BY ingest_date
        """

CUST_DATA_PRODUCT_TABLE = f"""
CREATE TABLE IF NOT EXISTS `{project_id_dw}.customer_data_product.customer_data`
(
  client_id STRING,
  ssn STRING,
  first_name STRING,
  middle_name INT64,
  last_name STRING,
  dob DATE,
  address_with_history ARRAY<STRUCT<status STRING, street STRING, city STRING, state STRING, zip_code INT64, WKT GEOGRAPHY, modify_date INT64>>,
  phone_num ARRAY<STRUCT<primary STRING, secondary INT64, modify_date INT64>>,
  email ARRAY<STRUCT<status STRING, primary STRING, secondary INT64, modify_date INT64>>, 
  ingestion_date DATE
)
        """

CUST_TOKENIZED_DATA_PRODUCT_TABLE = f"""
CREATE TABLE IF NOT EXISTS  `{project_id_dw}.customer_data_product.tokenized_customer_data`
(
  client_id BYTES,
  ssn BYTES,
  first_name BYTES,
  middle_name INT64,
  last_name BYTES,
  dob BYTES,
  address_with_history ARRAY<STRUCT<status STRING, street BYTES, city BYTES, state BYTES, zip_code BYTES, WKT BYTES, modify_date INT64>>,
  phone_num ARRAY<STRUCT<primary BYTES, secondary INT64, modify_date INT64>>,
  email ARRAY<STRUCT<status STRING, primary BYTES, secondary INT64, modify_date INT64>>,
  ingestion_date DATE
)

        """

CC_CUST_REF_TABLE = f"""
CREATE TABLE IF NOT EXISTS  `{project_id_dw}.customer_refined_data.{input_tbl_cc_cust}`
  (
  cc_number INT64,
  cc_expiry STRING,
  cc_provider STRING,
  cc_ccv INT64,
  cc_card_type STRING,
  client_id STRING,
  token STRING,
  dt STRING,
  ingest_date DATE )
PARTITION BY
  ingest_date
OPTIONS(
  partition_expiration_days=365,
  require_partition_filter=false
)

        """

CC_CUST_DATA_PRODUCT_TABLE = f"""
CREATE TABLE IF NOT EXISTS  `{project_id_dw}.customer_data_product.cc_customer_data`
(
  cc_number INT64,
  cc_expiry STRING,
  cc_provider STRING,
  cc_ccv INT64,
  cc_card_type STRING,
  client_id STRING,
  token STRING,
  ingest_date DATE )

        """

CUST_DP_INSERT = f"""
INSERT INTO
  `{project_id_dw}.customer_data_product.customer_data`
SELECT
  client_id AS client_id,
  ssn AS ssn,
  first_name AS first_name,
  NULL AS middle_name,
  last_name AS last_name,
  PARSE_DATE("%F",
    dob) AS dob,
  [STRUCT('current' AS status,
    cdd.street AS street,
    cdd.city,
    cdd.state,
    cdd.zip AS zip_code,
    ST_GeogPoint(cdd.latitude,
      cdd.longitude) AS WKT,
    NULL AS modify_date)] AS address_with_history,
  [STRUCT(cdd.phonenum AS primary,
    NULL AS secondary,
    NULL AS modify_date)] AS phone_num,
  [STRUCT('current' AS status,
    cdd.email AS primary,
    NULL AS secondary,
    NULL AS modify_date)] AS email,
  ingest_date AS ingest_date
FROM (
  SELECT
    * EXCEPT(rownum)
  FROM (
    SELECT
      *,
      ROW_NUMBER() OVER (PARTITION BY client_id, ssn, first_name, last_name, gender, street, city, state, zip, city_pop, job, dob, email, phonenum, profile ORDER BY client_id ) rownum
    FROM
      `{project_id_dw}.customer_refined_data.{input_tbl_cust}`
    WHERE
      ingest_date='{partition_date}' )
  WHERE
    rownum = 1 ) cdd;
    """

CUST_PRIVATE_KEYSET=f"""
INSERT INTO  `{project_id_dw}.customer_private.customer_keysets`
SELECT 
client_id as client_id,
  ssn as ssn,
  first_name  as first_name,
  last_name as last_name,
  gender as gender,
  street as street,
  city as city,
  state as state,
  zip as zip,
  latitude as latitude,
  longitude as longitude,
  city_pop as city_pop,
  job as job,
  PARSE_DATE("%F",dob) as dob,
  email as email,
  phonenum as phonenum,
KEYS.NEW_KEYSET('AEAD_AES_GCM_256') AS keyset ,
ingest_date  as ingest_date

FROM
( SELECT 
distinct client_id ,
  ssn ,
  first_name ,
  last_name ,
  gender ,
  street ,
  city ,
  state ,
  zip ,
  latitude ,
  longitude ,
  city_pop ,
  job ,
  dob ,
  email ,
  phonenum ,
  profile,
  ingest_date
  from 
  `{project_id_dw}.customer_refined_data.{input_tbl_cust}` where ingest_date='{partition_date}') cdd
  ;


"""

TOKENIZED_CUST_DATA=f"""
INSERT INTO  `{project_id_dw}.customer_data_product.tokenized_customer_data`
SELECT
  AEAD.ENCRYPT(keyset,'dummy_value',cast(client_id as String)) AS client_id,
  AEAD.ENCRYPT(keyset,'dummy_value',cast(ssn  as String)) AS ssn,
  AEAD.ENCRYPT(keyset,'dummy_value',cast(first_name as String)) AS first_name,
  NULL AS middle_name,
  AEAD.ENCRYPT(keyset,'dummy_value',cast(last_name  as String))AS last_name,
  AEAD.ENCRYPT(keyset,'dummy_value',cast(dob as String)) AS dob,
  [STRUCT('current' AS status,
    AEAD.ENCRYPT(keyset,'dummy_value',cast(cdk.street as String)) AS street,
    AEAD.ENCRYPT(keyset,'dummy_value',cast(cdk.city as String)) AS city,
    AEAD.ENCRYPT(keyset,'dummy_value',cast(cdk.state  as String)) AS state,
    AEAD.ENCRYPT(keyset,'dummy_value',cast(cdk.zip as String)) AS zip_code,
    AEAD.ENCRYPT(keyset,'dummy_value',cast(ST_GEOHASH(ST_GeogPoint(cdk.latitude, cdk.longitude))  as String)) as WKT,
    null AS modify_date)] AS address_with_history,
  [STRUCT(AEAD.ENCRYPT(keyset,'dummy_value',cast(cdk.phonenum  as String))AS primary,
    NULL AS secondary,
    NULL AS modify_date)] AS phone_num,
  [STRUCT('current' AS status,
    AEAD.ENCRYPT(keyset,'dummy_value',cast(cdk.email  as String)) AS primary,
    NULL AS secondary,
    NULL AS modify_date)] AS email,
      ingest_date as ingest_date

FROM
`{project_id_dw}.customer_private.customer_keysets` cdk where ingest_date='{partition_date}';
"""

CC_CUST_DATA=f"""
INSERT INTO  `{project_id_dw}.customer_data_product.cc_customer_data`
SELECT 
  cc_number ,
  cc_expiry ,
  cc_provider ,
  cc_ccv ,
  cc_card_type ,
  client_id ,
  token ,
  ingest_date 
  from 
  `{project_id_dw}.customer_refined_data.{input_tbl_cc_cust}`
where 
ingest_date='{partition_date}';
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
        'etl_customer_data_product_wf',
        catchup=False,
        schedule_interval=None,#datetime.timedelta(days=1),
        default_args=default_dag_args) as dag:

    bq_create_customer_ref_tbl = bigquery.BigQueryInsertJobOperator(
        task_id="bq_create_customer_ref_tbl",
        impersonation_chain=IMPERSONATION_CHAIN,
        configuration={
            "query": {
                "query": CUST_REF_DATA_TABLE,
                "useLegacySql": False
            }
        }
    )

    bq_create_customer_dp_tbl = bigquery.BigQueryInsertJobOperator(
        task_id="bq_create_customer_dp_tbl",
        impersonation_chain=IMPERSONATION_CHAIN,
        configuration={
            "query": {
                "query": CUST_DATA_PRODUCT_TABLE,
                "useLegacySql": False
            }
        }
    )

    bq_create_tokenized_customer_dp_tbl = bigquery.BigQueryInsertJobOperator(
        task_id="bq_create_tokenized_customer_dp_tbl",
        impersonation_chain=IMPERSONATION_CHAIN,
        configuration={
            "query": {
                "query": CUST_TOKENIZED_DATA_PRODUCT_TABLE,
                "useLegacySql": False
            }
        }
    )

    bq_create_cc_customer_ref_tbl = bigquery.BigQueryInsertJobOperator(
        task_id="bq_create_cc_customer_ref_tbl",
        impersonation_chain=IMPERSONATION_CHAIN,
        configuration={
            "query": {
                "query": CC_CUST_REF_TABLE,
                "useLegacySql": False
            }
        }
    )

    bq_create_cc_customer_dp_tbl = bigquery.BigQueryInsertJobOperator(
        task_id="bq_create_cc_customer_dp_tbl",
        impersonation_chain=IMPERSONATION_CHAIN,
        configuration={
            "query": {
                "query": CC_CUST_DATA_PRODUCT_TABLE,
                "useLegacySql": False
            }
        }
    )

    bq_insert_customer_dp_tbl = bigquery.BigQueryInsertJobOperator(
        task_id="bq_insert_customer_dp_tbl",
        impersonation_chain=IMPERSONATION_CHAIN,
        configuration={
            "query": {
                "query": CUST_DP_INSERT,
                "useLegacySql": False
            }
        }
    )

    bq_insert_customer_keyset_dp_tbl = bigquery.BigQueryInsertJobOperator(
        task_id="bq_insert_customer_keyset_dp_tbl",
        impersonation_chain=IMPERSONATION_CHAIN,
        configuration={
            "query": {
                "query": CUST_PRIVATE_KEYSET,
                "useLegacySql": False
            }
        }
    )

    bq_insert_customer_tokenized_dp_tbl = bigquery.BigQueryInsertJobOperator(
        task_id="bq_insert_customer_tokenized_dp_tbl",
        impersonation_chain=IMPERSONATION_CHAIN,
        configuration={
            "query": {
                "query": TOKENIZED_CUST_DATA,
                "useLegacySql": False
            }
        }
    )

    bq_insert_cc_customer_dp_tbl = bigquery.BigQueryInsertJobOperator(
        task_id="bq_insert_cc_customer_dp_tbl",
        impersonation_chain=IMPERSONATION_CHAIN,
        configuration={
            "query": {
                "query": CC_CUST_DATA,
                "useLegacySql": False
            }
        }
    )

    # [END composer_bigquery]

    chain(bq_create_customer_ref_tbl >> bq_create_customer_dp_tbl >> bq_create_tokenized_customer_dp_tbl >> bq_create_cc_customer_ref_tbl >> bq_create_cc_customer_dp_tbl >> bq_insert_customer_dp_tbl >> bq_insert_customer_keyset_dp_tbl  >> bq_insert_customer_tokenized_dp_tbl >> bq_insert_cc_customer_dp_tbl) 