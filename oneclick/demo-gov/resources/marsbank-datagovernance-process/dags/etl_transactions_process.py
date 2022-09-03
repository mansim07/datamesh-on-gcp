import datetime
from airflow import models
from airflow.operators import bash
from airflow.operators import email
from airflow.providers.google.cloud.operators import bigquery
from airflow.providers.google.cloud.transfers import bigquery_to_gcs
from airflow.utils import trigger_rule
from airflow.models.baseoperator import chain


IMPERSONATION_CHAIN = models.Variable.get('gcp_transactions_sa_acct')
REGION = models.Variable.get('gcp_project_region')
PROJECT_ID_DW = models.Variable.get('gcp_dw_project')
PROJECT_ID_DG = models.Variable.get('gcp_dg_project')
partition_date = models.Variable.get('transactions_partition_date')

CREATE_REFINED_AUTH_DATA = f"""
CREATE TABLE IF NOT EXISTS `{PROJECT_ID_DW}.pos_auth_refined_data.auth_data`
(
  cc_token STRING,
  card_read_type INT64,
  trans_start_ts FLOAT64,
  trans_end_ts FLOAT64,
  trans_type INT64,
  trans_amount FLOAT64,
  trans_currency STRING,
  trans_auth_code INT64,
  trans_auth_date FLOAT64,
  payment_method INT64,
  origination INT64,
  is_pin_entry INT64,
  is_signed INT64,
  is_unattended INT64,
  swipe_type INT64,
  merchant_id STRING,
  event_ids STRING,
  event STRING,
  Date String,
  ingest_date DATE
)
PARTITION BY ingest_date
"""

CREATE_DP_AUTH_DATA = f"""
CREATE TABLE IF NOT EXISTS `{PROJECT_ID_DW}.auth_data_product.auth_table`
(
  cc_token STRING,
  merchant_id STRING,
  card_read_type INT64,
  entry_mode STRING,
  trans_type INT64,
  value STRING,
  payment_method INT64,
  pymt_name STRING,
  swipe_code INT64,
  swipe_value STRING,
  trans_start_ts TIMESTAMP,
  trans_end_ts TIMESTAMP,
  trans_amount STRING,
  trans_currency STRING,
  trans_auth_code INT64,
  trans_auth_date FLOAT64,
  origination INT64,
  is_pin_entry INT64,
  is_signed INT64,
  is_unattended INT64,
  event_ids STRING,
  event STRING,
  version INT64,
  ingest_date DATE
)
PARTITION BY ingest_date;
"""
 
INSERT_DP_AUTH_DATA = f"""
INSERT INTO
  `{PROJECT_ID_DW}.auth_data_product.auth_table`
SELECT
cc_token,
merchant_id,
  crt.code as card_read_type,
      crt.entry_mode ,
    tt.trans_type,
      tt.value ,
    pm.pym_type_code as payment_method,
      pm.pymt_name,
    st.swipe_code,
      st.swipe_value,
    TIMESTAMP_SECONDS(cast(trans_start_ts as integer)) as trans_start_ts,
    TIMESTAMP_SECONDS(cast(trans_end_ts as integer)) as trans_end_ts,
    trans_amount,
      trans_currency,
    trans_auth_code,
      trans_auth_date,
      origination,
      is_pin_entry,
      is_signed,
      is_unattended,
    event_ids,
    event,
  NULL AS version,
  auth.ingest_date as ingest_date
FROM
  `{PROJECT_ID_DW}.pos_auth_refined_data.auth_data` auth
LEFT OUTER JOIN
  `{PROJECT_ID_DW}.auth_ref_data.card_read_type` crt
ON
  auth.card_read_type = crt.code
LEFT OUTER JOIN
  `{PROJECT_ID_DW}.auth_ref_data.payment_methods` pm
ON
  pm.pym_type_code=auth.payment_method
LEFT OUTER JOIN
  `{PROJECT_ID_DW}.auth_ref_data.trans_type` tt
ON
  tt.trans_type=auth.trans_type
LEFT OUTER JOIN
 `{PROJECT_ID_DW}.auth_ref_data.swiped_code` st
ON
  st.swipe_code=auth.swipe_type
  where auth.ingest_date='{partition_date}';
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
    'project_id': PROJECT_ID_DG,
    'region': REGION,

}

with models.DAG(
        'etl-transactions-data-process',
        catchup=False,
        schedule_interval=None,
        default_args=default_dag_args) as dag:

    bq_create_auth_tbl = bigquery.BigQueryInsertJobOperator(
        task_id="bq_create_auth_tbl",
        impersonation_chain=IMPERSONATION_CHAIN,
        configuration={
            "query": {
                "query": CREATE_DP_AUTH_DATA,
                "useLegacySql": False
            }
        }
    )

    bq_insert_trans_tbl = bigquery.BigQueryInsertJobOperator(
        task_id="bq_insert_trans_tbl",
        impersonation_chain=IMPERSONATION_CHAIN,
        configuration={
            "query": {
                "query": INSERT_DP_AUTH_DATA,
                "useLegacySql": False
            }
        }
    )
    
    chain(bq_create_auth_tbl >> bq_insert_trans_tbl)