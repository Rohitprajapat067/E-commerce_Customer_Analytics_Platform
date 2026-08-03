# Deployment Guide (AWS)

This project runs anywhere Docker runs. The suggested production path uses AWS EC2 + RDS + S3.

## 1. Provision Infrastructure

- **RDS (PostgreSQL 16)**: managed database replacing the `postgres` container. Enable automated backups and Multi-AZ for production.
- **EC2**: a single instance (or an ECS/Fargate service) running the `api`, `airflow-webserver`, `airflow-scheduler` containers via Docker Compose or a container orchestrator.
- **S3**: landing zone for raw source files before ETL picks them up, and a target for `dbt docs` static site hosting / Airflow log archival.

## 2. Configuration

1. Copy `.env.example` to `.env` and point `POSTGRES_HOST`/`PG_HOST` at the RDS endpoint, with real credentials (use AWS Secrets Manager or SSM Parameter Store in production instead of a plaintext `.env`).
2. Run the DDL in `sql/schema/` against RDS once (`psql -h <rds-endpoint> -U <user> -d <db> -f sql/schema/01_create_schemas.sql`, then the remaining files in order).
3. Update `dbt/ecommerce_analytics/profiles.yml.example` (copy to `profiles.yml`) with the RDS connection details, or keep using env vars.

## 3. Deploy Containers

```bash
# On the EC2 host
git clone <your-fork-url>
cd ecommerce-customer-analytics
cp .env.example .env   # fill in RDS + secrets
docker compose up -d --build api airflow-webserver airflow-scheduler prometheus grafana
```

(The `postgres` service in `docker-compose.yml` is only needed for local development — omit it in production and point everything at RDS via env vars.)

## 4. CI/CD

`.github/workflows/ci.yml` and `.github/workflows/dbt_ci.yml` run on every push. Extend them with a deploy job that:
1. Builds and pushes the `api` image to ECR.
2. Runs `docker compose pull && docker compose up -d` on the EC2 host over SSH, or triggers an ECS service update.

## 5. Scheduling

Airflow's scheduler container handles the daily ETL → dbt run → dbt test pipeline. For a lighter-weight production setup, Airflow can be swapped for a managed alternative (e.g. Amazon MWAA) pointed at the same `airflow/dags/` folder in S3.

## 6. Monitoring & Backups

- Point Prometheus at the API's `/health` endpoint and add a Postgres exporter for RDS-level metrics.
- Enable RDS automated snapshots (daily) and set a retention window appropriate to your recovery point objective.
- For disaster recovery, keep `sql/schema/`, `dbt/`, and `data/raw/` in version control (already the case) so the warehouse can be rebuilt from scratch against a fresh RDS instance.
