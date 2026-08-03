# E-commerce Customer Analytics Platform

An end-to-end, production-style analytics platform for e-commerce customer data — built with PostgreSQL, Python ETL, dbt, Airflow, FastAPI, Docker, and GitHub Actions.

> This repo is a working scaffold: it runs locally with Docker Compose, loads sample data, transforms it through a Bronze → Silver → Gold warehouse with dbt, and serves KPIs through a FastAPI service. Swap in your own source data and extend the analytics layer as needed.

## Architecture

```
CSV / API sources
      │
      ▼
 Python ETL (etl/)  ──────────────►  PostgreSQL "raw" schema (Bronze)
                                            │
                                            ▼
                                     dbt staging models (Silver)
                                            │
                                            ▼
                                 dbt mart models: RFM, CLV, cohorts (Gold)
                                            │
                              ┌─────────────┴─────────────┐
                              ▼                            ▼
                        FastAPI (api/)              Power BI (dashboards/)
                              │
                              ▼
                    Prometheus + Grafana (monitoring/)
```

Airflow (`airflow/dags/`) orchestrates the ETL → dbt run → dbt test pipeline on a schedule.

See [`docs/architecture.md`](docs/architecture.md), [`docs/ERD.md`](docs/ERD.md), [`docs/HLD.md`](docs/HLD.md) and [`docs/LLD.md`](docs/LLD.md) for design details.

## Tech Stack

| Layer | Technology |
|---|---|
| Source | CSV (synthetic sample data included) |
| Database | PostgreSQL 16 |
| ETL | Python 3.12 (Pandas, SQLAlchemy) |
| Transform | dbt (dbt-postgres) |
| Orchestration | Apache Airflow |
| Analytics | SQL (window functions, RFM, CLV, cohort, churn, market basket) |
| API | FastAPI |
| Dashboard | Power BI (connects over Postgres) |
| Container | Docker / Docker Compose |
| CI/CD | GitHub Actions |
| Monitoring | Prometheus + Grafana |

## Repository Layout

```
project/
├── data/raw/          sample source CSVs
├── sql/schema/        DDL: schemas, dimension/fact tables, constraints, indexes
├── sql/analytics/     20+ standalone analytics SQL queries (RFM, CLV, cohort, churn...)
├── etl/               Python extract/load scripts (Bronze layer loader)
├── dbt/               dbt project: staging + marts models, tests, docs
├── airflow/dags/       DAG orchestrating ETL → dbt run → dbt test
├── api/                FastAPI service exposing KPI endpoints (Swagger at /docs)
├── dashboards/         Power BI connection guide
├── monitoring/         Prometheus + Grafana config
├── tests/              unit tests for ETL and API
└── .github/workflows/  CI: lint, unit tests, dbt build
```

## Quickstart

```bash
git clone <your-fork-url>
cd ecommerce-customer-analytics
cp .env.example .env

# Bring up Postgres, Airflow, API, monitoring
docker compose up -d --build

# Run the ETL once to load sample CSVs into the "raw" schema
docker compose exec api python -m etl.run_etl

# Build the dbt warehouse (staging -> marts)
docker compose exec api bash -c "cd /app/dbt/ecommerce_analytics && dbt run && dbt test"
```

- API + Swagger docs: http://localhost:8000/docs
- Airflow UI: http://localhost:8080 (admin/admin, see `.env.example`)
- Postgres: `localhost:5432` (see `.env.example` for credentials)
- Grafana: http://localhost:3000

## KPIs / Analytics Covered

- RFM segmentation (Recency, Frequency, Monetary)
- Customer Lifetime Value (CLV)
- Cohort retention analysis
- Churn indicators
- Market basket / product affinity
- Revenue, AOV, and order KPIs via window functions

See [`sql/analytics/`](sql/analytics) for the raw SQL and [`dbt/ecommerce_analytics/models/marts`](dbt/ecommerce_analytics/models/marts) for the dbt-modeled equivalents.

## Power BI

`.pbix` files are binary and environment-specific, so this repo ships a connection guide instead of a prebuilt file — see [`dashboards/README.md`](dashboards/README.md). Point Power BI's Postgres connector at the `analytics` (gold) schema and the four suggested dashboards (Executive KPI, Customer, Product, Revenue) build directly on top of the mart tables/views.

## CI/CD

`.github/workflows/ci.yml` runs linting and unit tests on every push/PR. `.github/workflows/dbt_ci.yml` spins up a throwaway Postgres service and runs `dbt build` against it to catch model/test regressions.

## Deployment

See [`docs/deployment_guide.md`](docs/deployment_guide.md) for the AWS EC2 + RDS + S3 deployment path.

## License

MIT — see [`LICENSE`](LICENSE).
