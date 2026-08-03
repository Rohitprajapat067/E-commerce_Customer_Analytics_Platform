# Power BI Dashboards

`.pbix` files are binary and machine/environment-specific, so this repo ships a
connection guide instead of a prebuilt file. Build the four dashboards below
directly on top of the Gold-layer tables produced by dbt.

## Connect Power BI to the warehouse

1. **Get Data → PostgreSQL database**.
2. Server: `<your host>:5432` (e.g. `localhost:5432` locally, or the RDS endpoint in production).
3. Database: `ecommerce_analytics`.
4. Load the following tables/views from the `analytics` schema:
   - `dim_customers`
   - `dim_products`
   - `fct_orders`
   - `customer_rfm`
   - `customer_clv`
5. In Power BI's Model view, create relationships:
   - `fct_orders.customer_id` → `dim_customers.customer_id` (many-to-one)
   - `fct_orders.customer_id` → `customer_rfm.customer_id` / `customer_clv.customer_id` (one-to-one)
   - Optionally load `raw.order_items` + `raw.products` to relate `dim_products` at the line-item grain.

## Suggested Dashboards

### 1. Executive KPI
- Total revenue, total orders, AOV, active customers (cards from `fct_orders`).
- Monthly revenue trend (line chart, `fct_orders.order_date` by month).
- Order status breakdown (donut chart).

### 2. Customer
- RFM segment distribution (bar chart from `customer_rfm.rfm_segment`).
- Top customers by CLV (table from `customer_clv`, sorted descending).
- New vs. returning customer revenue split by month.
- Churn/at-risk customer list (`dim_customers` filtered on `days_since_last_order`).

### 3. Product
- Revenue and units sold by category (`dim_products`, bar chart).
- Top 10 products by revenue (table).
- Margin analysis (`unit_margin` vs. `total_revenue`, scatter).

### 4. Revenue
- Revenue by country / payment method (`fct_orders` joined to `dim_customers`).
- Daily/weekly revenue trend with moving average.
- Cohort retention heatmap (import `sql/analytics/03_cohort_retention.sql` as a custom query / dbt model as a Power Query source).

## Refresh

Schedule a Power BI scheduled refresh (Pro/Premium) pointed at the same
Postgres connection, timed to run after the nightly Airflow DAG completes
(`dbt_docs_generate` task finishing is a good signal).
