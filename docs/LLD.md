# Low-Level Design (LLD)

## Repository Layout & Ownership

```
project/
├── data/
│   ├── generate_sample_data.py   # synthetic data generator (stdlib only)
│   └── raw/*.csv                 # sample source files
├── docker/                       # (docker-compose.yml lives at repo root)
├── airflow/dags/*.py             # Airflow DAGs
├── dbt/ecommerce_analytics/
│   ├── models/staging/*.sql      # Silver: 1:1 cleaned source models
│   ├── models/marts/*.sql        # Gold: dims, facts, RFM, CLV
│   └── models/**/schema.yml      # sources, tests, docs
├── api/*.py                      # FastAPI app (routers/, schemas.py, database.py)
├── sql/schema/*.sql              # raw DDL: schemas, tables, indexes, constraints
├── sql/analytics/*.sql           # standalone analytics query library
├── dashboards/                   # Power BI connection guide
├── monitoring/                   # Prometheus + Grafana config
├── tests/                        # pytest unit tests (ETL + API)
└── .github/workflows/*.yml       # CI pipelines
```

## Module Details

### `etl/`
- `extract.py`: `extract_all() -> dict[str, DataFrame]`, reads every file in `TABLES` from `data/raw/`.
- `load.py`: `load_table(engine, df, table, mode, watermark_col)`. `full_refresh` truncates then appends (preserving DDL constraints); `incremental` filters rows newer than `MAX(watermark_col)` already in the target table.
- `run_etl.py`: entrypoint; defines `LOAD_ORDER` (parents before children for FK integrity) and which tables load incrementally.

### `dbt/ecommerce_analytics/models/staging/`
One model per raw table (`stg_customers`, `stg_products`, `stg_orders`, `stg_order_items`): trims/casts types, computes light derived columns (e.g. `line_revenue`), no business logic beyond cleaning.

### `dbt/ecommerce_analytics/models/marts/`
- `dim_customers`, `dim_products`: dimension tables enriched with aggregated stats via a `left join` to an aggregation CTE.
- `fct_orders`: order-grain fact, one row per order with rolled-up item totals.
- `customer_rfm`: `NTILE(4)` window functions score recency/frequency/monetary; a `CASE` expression maps scores to a segment label.
- `customer_clv`: historical revenue + a simple `avg_order_value x annualized_frequency` predictive estimate.

### `api/`
- `database.py`: SQLAlchemy engine from `PG_*` env vars; `run_query()` helper returns rows as `list[dict]`.
- `routers/kpi.py`: `/kpi/revenue`, `/kpi/revenue/monthly`.
- `routers/customers.py`: `/customers/rfm`, `/customers/clv`.
- `routers/products.py`: `/products/performance`.
- All endpoints query the `raw` schema directly (so the API works even before `dbt run`), mirroring the logic in the dbt marts.

### `airflow/dags/ecommerce_analytics_dag.py`
Linear DAG: `extract_and_load_bronze (PythonOperator)` → `dbt_deps` → `dbt_run` → `dbt_test` → `dbt_docs_generate` (all `BashOperator`, `retries=2`).

## Data Contracts (enforced by dbt tests)
- `customer_id`, `product_id`, `order_id`, `order_item_id` are unique + not null at their respective grains.
- `orders.customer_id` and `order_items.{order_id,product_id}` have referential integrity tests (`relationships`).
- `orders.order_status` and `customer_rfm.rfm_segment` are constrained to an `accepted_values` list.

## Naming Conventions
- Snake_case throughout SQL and Python.
- Staging models prefixed `stg_`; marts use plain business names (`dim_`, `fct_`, or descriptive nouns like `customer_rfm`).
- Money columns use `numeric(10,2)`; dates use native `date`/`timestamp` types, never strings.
