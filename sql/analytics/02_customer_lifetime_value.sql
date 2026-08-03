-- =====================================================================
-- Customer Lifetime Value (CLV)
-- =====================================================================

-- Q1: Historical CLV per customer (revenue-to-date)
WITH order_facts AS (
    SELECT
        o.customer_id,
        o.order_id,
        o.order_date,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100.0)) AS order_value
    FROM raw.orders o
    JOIN raw.order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'completed'
    GROUP BY o.customer_id, o.order_id, o.order_date
)
SELECT
    customer_id,
    SUM(order_value) AS total_revenue,
    COUNT(order_id) AS total_orders,
    ROUND(SUM(order_value) / NULLIF(COUNT(order_id), 0), 2) AS avg_order_value,
    (MAX(order_date) - MIN(order_date)) AS customer_lifespan_days
FROM order_facts
GROUP BY customer_id
ORDER BY total_revenue DESC;

-- Q2: Simple predictive CLV = avg order value x purchase frequency x
-- estimated lifespan (12 months), a common lightweight CLV heuristic
WITH order_facts AS (
    SELECT
        o.customer_id,
        o.order_id,
        o.order_date,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100.0)) AS order_value
    FROM raw.orders o
    JOIN raw.order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'completed'
    GROUP BY o.customer_id, o.order_id, o.order_date
),
customer_agg AS (
    SELECT
        customer_id,
        SUM(order_value) AS total_revenue,
        COUNT(order_id) AS total_orders,
        (MAX(order_date) - MIN(order_date)) AS lifespan_days
    FROM order_facts
    GROUP BY customer_id
)
SELECT
    customer_id,
    total_revenue,
    total_orders,
    ROUND(total_revenue / NULLIF(total_orders, 0), 2) AS avg_order_value,
    ROUND(total_orders::numeric / NULLIF(GREATEST(lifespan_days, 1) / 365.0, 0), 2) AS purchase_freq_per_year,
    ROUND(
        (total_revenue / NULLIF(total_orders, 0))
        * (total_orders::numeric / NULLIF(GREATEST(lifespan_days, 1) / 365.0, 0))
        * 1  -- projected years
    , 2) AS predicted_annual_clv
FROM customer_agg
ORDER BY predicted_annual_clv DESC;

-- Q3: CLV by acquisition cohort (signup month)
WITH order_facts AS (
    SELECT
        o.customer_id,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100.0)) AS order_value
    FROM raw.orders o
    JOIN raw.order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'completed'
    GROUP BY o.customer_id, o.order_id
)
SELECT
    date_trunc('month', c.signup_date)::date AS signup_month,
    COUNT(DISTINCT c.customer_id) AS customers,
    ROUND(SUM(f.order_value), 2) AS cohort_total_revenue,
    ROUND(SUM(f.order_value) / NULLIF(COUNT(DISTINCT c.customer_id), 0), 2) AS avg_clv_per_customer
FROM raw.customers c
LEFT JOIN order_facts f ON f.customer_id = c.customer_id
GROUP BY 1
ORDER BY 1;
