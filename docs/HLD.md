# High-Level Design (HLD)

## 1. Ingestion Layer
- **Input**: CSV files in `data/raw/` (swap for API/Kaggle sources by extending `etl/extract.py`).
- **Component**: `etl/extract.py` reads sources into Pandas DataFrames; `etl/load.py` writes them into PostgreSQL.
- **Modes**: full-refresh for dimensions, incremental (watermark-based) for the orders fact.

## 2. Data Warehouse (Bronze / Silver / Gold)
- **PostgreSQL 16**, three schemas: `raw` (Bronze), `staging` (Silver), `analytics` (Gold).
- **dbt** owns all Silver/Gold transformation, testing, and documentation.

## 3. Analytics Layer
- Hand-written SQL library in `sql/analytics/` (RFM, CLV, cohort, churn, market basket, revenue KPIs, window functions) — usable directly in a SQL client or Power BI's custom-query mode.
- Equivalent logic is also materialized as dbt mart models for reuse by the API and BI tools.

## 4. API Layer
- **FastAPI** service (`api/`) exposing read-only KPI, RFM, CLV, and product-performance endpoints over the warehouse.
- Auto-generated OpenAPI/Swagger docs at `/docs`.
- Stateless; horizontally scalable behind a load balancer in production.

## 5. Visualization Layer
- **Power BI** connects directly to the `analytics` (Gold) schema via the native Postgres connector.
- Four suggested dashboards: Executive KPI, Customer, Product, Revenue (see `dashboards/README.md`).

## 6. Orchestration
- **Apache Airflow** DAG (`airflow/dags/ecommerce_analytics_dag.py`) runs daily: ETL → `dbt run` → `dbt test` → `dbt docs generate`.

## 7. Monitoring & CI/CD
- **Prometheus + Grafana** for container/infra observability (extend with a Postgres exporter and FastAPI instrumentation for production).
- **GitHub Actions**: lint + unit tests on every push; a separate workflow spins up ephemeral Postgres and runs `dbt build` to catch model/test regressions before merge.

## Non-Functional Considerations
- **Idempotency**: all loads and dbt models are safe to re-run.
- **Testability**: dbt schema tests (`unique`, `not_null`, `relationships`, `accepted_values`) act as data-quality gates.
- **Portability**: everything runs via Docker Compose locally; the same images deploy to AWS EC2/RDS (see `deployment_guide.md`).
- **Extensibility**: adding a new source is a matter of extending `etl/extract.py` + `TABLES`, adding a raw DDL table, and a new dbt staging model.
