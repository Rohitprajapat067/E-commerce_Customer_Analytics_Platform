"""
Ecommerce Customer Analytics pipeline DAG.

Orchestrates: Python ETL (Bronze load) -> dbt run (Silver+Gold build)
-> dbt test (data quality gates).

Runs daily by default; adjust `schedule` as needed.
"""
from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator

default_args = {
    "owner": "analytics",
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
}

DBT_PROJECT_DIR = "/opt/airflow/dbt/ecommerce_analytics"
DBT_PROFILES_DIR = "/opt/airflow/dbt/ecommerce_analytics"


def run_etl():
    import sys

    sys.path.insert(0, "/opt/airflow")
    from etl.run_etl import main as run_etl_main

    run_etl_main()


with DAG(
    dag_id="ecommerce_analytics_pipeline",
    description="ETL -> dbt run -> dbt test for the e-commerce analytics warehouse",
    default_args=default_args,
    start_date=datetime(2026, 1, 1),
    schedule="@daily",
    catchup=False,
    max_active_runs=1,
    tags=["ecommerce", "analytics", "elt"],
) as dag:

    extract_and_load = PythonOperator(
        task_id="extract_and_load_bronze",
        python_callable=run_etl,
    )

    dbt_deps = BashOperator(
        task_id="dbt_deps",
        bash_command=f"cd {DBT_PROJECT_DIR} && dbt deps --profiles-dir {DBT_PROFILES_DIR} || true",
    )

    dbt_run = BashOperator(
        task_id="dbt_run",
        bash_command=f"cd {DBT_PROJECT_DIR} && dbt run --profiles-dir {DBT_PROFILES_DIR}",
    )

    dbt_test = BashOperator(
        task_id="dbt_test",
        bash_command=f"cd {DBT_PROJECT_DIR} && dbt test --profiles-dir {DBT_PROFILES_DIR}",
    )

    dbt_docs = BashOperator(
        task_id="dbt_docs_generate",
        bash_command=f"cd {DBT_PROJECT_DIR} && dbt docs generate --profiles-dir {DBT_PROFILES_DIR}",
    )

    extract_and_load >> dbt_deps >> dbt_run >> dbt_test >> dbt_docs
