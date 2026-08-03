-- Bronze (raw) tables. ETL loads sample CSVs directly into these.
-- Star-schema dimensions live here in raw form; dbt promotes them to
-- clean staging/dim models in the "staging" and "analytics" schemas.

CREATE TABLE IF NOT EXISTS raw.customers (
    customer_id     INTEGER PRIMARY KEY,
    first_name      VARCHAR(100),
    last_name       VARCHAR(100),
    email           VARCHAR(255),
    country         VARCHAR(100),
    city            VARCHAR(100),
    signup_date     DATE,
    customer_segment VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS raw.products (
    product_id      INTEGER PRIMARY KEY,
    product_name    VARCHAR(255),
    category        VARCHAR(100),
    sub_category    VARCHAR(100),
    unit_price      NUMERIC(10, 2),
    unit_cost       NUMERIC(10, 2)
);

CREATE TABLE IF NOT EXISTS raw.date_dim (
    date_key        DATE PRIMARY KEY,
    year            INTEGER,
    quarter         INTEGER,
    month           INTEGER,
    month_name      VARCHAR(20),
    day             INTEGER,
    day_of_week     INTEGER,
    day_name        VARCHAR(20),
    is_weekend      BOOLEAN
);
