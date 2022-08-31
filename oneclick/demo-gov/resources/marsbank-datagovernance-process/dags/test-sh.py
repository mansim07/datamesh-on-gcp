import datetime
from airflow import models
from airflow.operators import bash
from airflow.operators import email
from airflow.providers.google.cloud.operators import bigquery
from airflow.providers.google.cloud.transfers import bigquery_to_gcs
from airflow.utils import trigger_rule
from airflow.models.baseoperator import chain
from airflow.operators.bash_operator import BashOperator


IMPERSONATION_CHAIN = models.Variable.get('gcp_transactions_consumer_sa_acct')
REGION = models.Variable.get('gcp_project_region')
PROJECT_ID_DW = models.Variable.get('gcp_dw_project')
PROJECT_ID_DG = models.Variable.get('gcp_dg_project')
partition_date = models.Variable.get('transactions_partition_date')


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
        'generate-customer-data',
        catchup=False,
        schedule_interval=None,
        default_args=default_dag_args) as dag:


    generate_customer_data = BashOperator(
        task_id="generate_customer_data",
        bash_command="/home/airflow/gcs/dags/datagenerator/generate_customer_data.sh /home/airflow/gcs/dags/datagenerator",
    )
    
    chain(generate_customer_data)