from airflow import DAG
from airflow.providers.amazon.aws.operators.glue import GlueJobOperator
from airflow.providers.amazon.aws.sensors.glue import GlueJobSensor
from datetime import datetime, timedelta

dag = DAG(
  'glue_etl_pipeline',
  description='A DAG to trigger AWS Glue ETL job',
  schedule_interval=None,
  catchup=False,
  tags=['glue', 'etl', 'data-pipeline'],
  default_args={
    'owner': 'data-team',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
  },
)

run_glue_job = GlueJobOperator(
  task_id='run_glue_etl_job',
  job_name='my-glue-etl-job',
  aws_conn_id='aws_default',
  region_name='us-east-1',
  iam_role_name='AWSGlueServiceRole',
  job_desc='Running Glue ETL job from Airflow',
  script_args={
    '--job-bookmark-option': 'job-bookmark-enable',
    '--enable-metrics': '',
    '--enable-continuous-cloudwatch-log': '',
  },
  dag=dag,
)

wait_for_glue_job = GlueJobSensor(
  task_id='wait_for_glue_job_completion',
  job_name='my-glue-etl-job',
  run_id="{{ task_instance.xcom_pull(task_ids='run_glue_etl_job', key='return_value') }}",
  aws_conn_id='aws_default',
  timeout=60 * 30,
  poke_interval=10,
  dag=dag,
)

run_glue_job >> wait_for_glue_job
