"""Trigger Dags #1 and #2 and do something if they succeed."""
from airflow import DAG
from airflow.operators.sensors import ExternalTaskSensor
from airflow.operators.dummy_operator import DummyOperator
from airflow.utils.dates import days_ago


with DAG(
        'master_dag',
        schedule_interval='*/1 * * * *',  # Every 1 minute
        start_date=days_ago(0),
        catchup=False) as dag:
    def greeting():
        """Just check that the DAG is started in the log."""
        import logging
        logging.info('Hello World from DAG MASTER')

    externalsensor1 = ExternalTaskSensor(
        task_id='data_governane_dq_customer_data_product_wf',
        external_dag_id='dag_1',
        external_task_id=None,  # wait for whole DAG to complete
        check_existence=True,
        timeout=120)

    externalsensor2 = ExternalTaskSensor(
        task_id='dag_2_completed_status',
        external_dag_id='data_governance_customer_quality_tag',
        external_task_id=None,  # wait for whole DAG to complete
        check_existence=True,
        timeout=120)

    dq_complete = DummyOperator(task_id='Completed Customer DQ Tagging')

    externalsensor1 >> externalsensor2 >> dq_complete