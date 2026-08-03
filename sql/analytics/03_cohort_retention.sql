-- =====================================================================
-- Cohort Retention Analysis
-- =====================================================================

-- Q1: Assign each customer to a monthly acquisition cohort and
-- compute months-since-acquisition for every order
WITH first_orders AS (
    SELECT customer_id, MIN(order_date) AS first_order_date
    FROM raw.orders
    WHERE order_status = 'completed'
    GROUP BY customer_id
),
cohort_orders AS (
    SELECT
        o.customer_id,
        date_trunc('month', f.first_order_date)::date AS cohort_month,
        date_trunc('month', o.order_date)::date AS order_month
    FROM raw.orders o
    JOIN first_orders f ON f.customer_id = o.customer_id
    WHERE o.order_status = 'completed'
)
SELECT
    cohort_month,
    order_month,
    (DATE_PART('year', order_month) - DATE_PART('year', cohort_month)) * 12
        + (DATE_PART('month', order_month) - DATE_PART('month', cohort_month)) AS month_index,
    COUNT(DISTINCT customer_id) AS active_customers
FROM cohort_orders
GROUP BY cohort_month, order_month
ORDER BY cohort_month, order_month;

-- Q2: Cohort retention matrix as % of cohort size retained at each
-- month-index (pivot month_index -> columns in your BI tool / dbt)
WITH first_orders AS (
    SELECT customer_id, MIN(order_date) AS first_order_date
    FROM raw.orders
    WHERE order_status = 'completed'
    GROUP BY customer_id
),
cohort_sizes AS (
    SELECT date_trunc('month', first_order_date)::date AS cohort_month,
           COUNT(*) AS cohort_size
    FROM first_orders
    GROUP BY 1
),
cohort_orders AS (
    SELECT
        o.customer_id,
        date_trunc('month', f.first_order_date)::date AS cohort_month,
        (DATE_PART('year', date_trunc('month', o.order_date)) - DATE_PART('year', date_trunc('month', f.first_order_date))) * 12
          + (DATE_PART('month', date_trunc('month', o.order_date)) - DATE_PART('month', date_trunc('month', f.first_order_date))) AS month_index
    FROM raw.orders o
    JOIN first_orders f ON f.customer_id = o.customer_id
    WHERE o.order_status = 'completed'
)
SELECT
    co.cohort_month,
    co.month_index,
    cs.cohort_size,
    COUNT(DISTINCT co.customer_id) AS retained_customers,
    ROUND(100.0 * COUNT(DISTINCT co.customer_id) / NULLIF(cs.cohort_size, 0), 1) AS retention_pct
FROM cohort_orders co
JOIN cohort_sizes cs ON cs.cohort_month = co.cohort_month
GROUP BY co.cohort_month, co.month_index, cs.cohort_size
ORDER BY co.cohort_month, co.month_index;
