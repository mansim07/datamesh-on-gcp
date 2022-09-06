"""Trigger Dags #1 and #2 and do something if they succeed."""
from airflow import DAG
from airflow.sensors.external_task import ExternalTaskSensor
from airflow.operators.dummy_operator import DummyOperator
from airflow.utils.dates import days_ago

import datetime
from airflow.operators import bash
import uuid
import os
from airflow import models
from airflow.models.baseoperator import chain
from airflow.providers.google.cloud.operators.dataplex import (
    DataplexCreateTaskOperator,
    DataplexDeleteTaskOperator,
    DataplexGetTaskOperator,
    DataplexListTasksOperator,
)
from airflow.providers.google.cloud.sensors.dataplex import DataplexTaskStateSensor
from airflow.operators.python_operator import PythonOperator
from airflow.operators.bash_operator import BashOperator
import logging
import io
from airflow.operators import dummy_operator
import google.auth
from requests_oauth2 import OAuth2BearerToken
import requests
from airflow.operators.bash import BashOperator
from airflow.operators.python import BranchPythonOperator
import time
import json
import csv




yesterday = datetime.datetime.combine(
    datetime.datetime.today() - datetime.timedelta(1),
    datetime.datetime.min.time())
    
default_args = {
    'owner': 'airflow',
    'start_date': yesterday,
    'depends_on_past': False,
    'email': [''],
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': datetime.timedelta(minutes=5),
}


with DAG(
        'master_dag_merchants_dq',
        schedule_interval=None,
        default_args=default_args,  # Every 1 minute
      #  start_date=days_ago(0),
        catchup=False) as dag:
    def greeting():
        """Just check that the DAG is started in the log."""
        import logging
        logging.info('Hello World from DAG MASTER')

    externalsensor1 = ExternalTaskSensor(
        task_id='data_governance_merchant_quality_tag',
        external_dag_id='data_governance_dq_merchant_data_product_wf',
        external_task_id=None,  # wait for whole DAG to complete
        check_existence=True,
        timeout=120)

    externalsensor2 = ExternalTaskSensor(
        task_id='dag_2_completed_status',
        external_dag_id='data_governance_dq_merchant_data_product_wf',
        external_task_id=None,  # wait for whole DAG to complete
        check_existence=True,
        timeout=120)

    dq_complete = DummyOperator(task_id='cmerchantr_dq_tagging')

    externalsensor1 >> externalsensor2 >> dq_complete