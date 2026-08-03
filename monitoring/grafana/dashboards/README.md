# Grafana Dashboards

Grafana ships blank in this repo's Docker Compose (`ecom_grafana` on
`localhost:3000`, default `admin`/`admin` — override via `.env`).

## Add Prometheus as a data source

1. Grafana → Connections → Data sources → Add data source → Prometheus.
2. URL: `http://prometheus:9090` (container-to-container name from Compose).
3. Save & test.

## Suggested panels

Once the API exposes a `/metrics` endpoint (see `monitoring/prometheus.yml`
comments — add `prometheus-fastapi-instrumentator` to `api/requirements.txt`
and instrument `api/main.py`), build panels for:

- Request rate and p95 latency per endpoint (`/kpi/revenue`, `/customers/rfm`, etc.)
- Error rate (5xx responses)
- Container CPU/memory (via `cadvisor` if added to the Compose stack)
- Postgres connection count and query duration (via `postgres_exporter`)

## Airflow observability

Airflow's own webserver (`localhost:8080`) already surfaces DAG run history,
task duration, and failure alerts — no separate Grafana panel is required
unless you want long-term trend charts, in which case export Airflow
metrics via `statsd_exporter` and scrape them the same way as above.
