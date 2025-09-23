from airflow import DAG
from airflow.providers.amazon.aws.operators.emr import (
    EmrCreateJobFlowOperator,
    EmrAddStepsOperator,
    EmrTerminateJobFlowOperator
)
from airflow.providers.amazon.aws.sensors.emr import EmrStepSensor
from datetime import datetime, timedelta

EMR_CONFIG = {
    "Name": "emr-spark-cluster",
    "ReleaseLabel": "emr-6.10.0",
    "Applications": [{"Name": "Spark"}, {"Name": "Hadoop"}],
    "Instances": {
        "InstanceGroups": [
            {
                "Name": "Master nodes",
                "Market": "ON_DEMAND",
                "InstanceRole": "MASTER",
                "InstanceType": "m5.xlarge",
                "InstanceCount": 1,
            },
            {
                "Name": "Worker nodes",
                "Market": "SPOT",
                "InstanceRole": "CORE",
                "InstanceType": "m5.large",
                "InstanceCount": 2,
            },
        ],
        "Ec2KeyName": "your-ec2-key",
        "KeepJobFlowAliveWhenNoSteps": False,
        "TerminationProtected": False,
    },
    "JobFlowRole": "EMR_EC2_DefaultRole",
    "ServiceRole": "EMR_DefaultRole",
    "LogUri": "s3://your-emr-logs-bucket/logs/",
    "BootstrapActions": [],
    "Tags": [
        {"Key": "Environment", "Value": "production"},
        {"Key": "Project", "Value": "data-pipeline"},
    ],
}

SPARK_STEPS = [
    {
        "Name": "data-processing-step",
        "ActionOnFailure": "TERMINATE_CLUSTER",
        "HadoopJarStep": {
            "Jar": "command-runner.jar",
            "Args": [
                "spark-submit",
                "--deploy-mode", "cluster",
                "--master", "yarn",
                "--conf", "spark.sql.adaptive.enabled=true",
                "--conf", "spark.sql.adaptive.coalescePartitions.enabled=true",
                "--conf", "spark.dynamicAllocation.enabled=true",
                "--conf", "spark.dynamicAllocation.minExecutors=1",
                "--conf", "spark.dynamicAllocation.maxExecutors=10",
                "s3://your-scripts-bucket/spark/data_processing.py",
                "--input-path", "s3://your-data-bucket/input/",
                "--output-path", "s3://your-data-bucket/output/",
                "--date", "{{ ds }}",
            ],
        },
    }
]

dag = DAG(
    'emr_spark_pipeline',
    description='EMR Spark data processing pipeline',
    default_args={
        'owner': 'data-team',
        'depends_on_past': False,
        'start_date': datetime(2024, 1, 1),
        'email_on_failure': True,
        'email_on_retry': False,
        'retries': 1,
        'retry_delay': timedelta(minutes=5),
    },
    schedule_interval='0 2 * * *',
    catchup=False,
    tags=['emr', 'spark', 'etl', 'data-pipeline'],
)

# Create EMR cluster
create_emr_cluster = EmrCreateJobFlowOperator(
    task_id='create_emr_cluster',
    job_flow_overrides=EMR_CONFIG,
    aws_conn_id='aws_default',
    region_name='us-east-1',
    dag=dag,
)

# Add Spark steps to the cluster
add_spark_steps = EmrAddStepsOperator(
    task_id='add_spark_steps',
    job_flow_id="{{ task_instance.xcom_pull(task_ids='create_emr_cluster', key='return_value') }}",
    steps=SPARK_STEPS,
    aws_conn_id='aws_default',
    dag=dag,
)

# Wait for steps to complete
wait_for_steps = EmrStepSensor(
    task_id='wait_for_spark_step_completion',
    job_flow_id="{{ task_instance.xcom_pull(task_ids='create_emr_cluster', key='return_value') }}",
    step_id="{{ task_instance.xcom_pull(task_ids='add_spark_steps', key='return_value')[0] }}",
    aws_conn_id='aws_default',
    timeout=60 * 60,  # 1 hour timeout
    poke_interval=30,  # Check every 30 seconds
    dag=dag,
)

# Terminate EMR cluster
terminate_emr_cluster = EmrTerminateJobFlowOperator(
    task_id='terminate_emr_cluster',
    job_flow_id="{{ task_instance.xcom_pull(task_ids='create_emr_cluster', key='return_value') }}",
    aws_conn_id='aws_default',
    trigger_rule='all_done',  # Run even if previous tasks failed
    dag=dag,
)

# Task dependencies
create_emr_cluster >> add_spark_steps >> wait_for_steps >> terminate_emr_cluster
