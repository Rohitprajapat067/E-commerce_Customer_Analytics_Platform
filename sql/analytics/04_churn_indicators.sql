-- =====================================================================
-- Churn Indicators
-- =====================================================================

-- Q1: Days since last order + churn flag (no completed order in 90 days)
WITH order_facts AS (
    SELECT customer_id, MAX(order_date) AS last_order_date, COUNT(*) AS total_orders
    FROM raw.orders
    WHERE order_status = 'completed'
    GROUP BY customer_id
)
SELECT
    c.customer_id,
    c.customer_segment,
    o.last_order_date,
    (CURRENT_DATE - o.last_order_date) AS days_since_last_order,
    COALESCE(o.total_orders, 0) AS total_orders,
    CASE
        WHEN o.last_order_date IS NULL THEN 'Never Purchased'
        WHEN (CURRENT_DATE - o.last_order_date) > 90 THEN 'Churned'
        WHEN (CURRENT_DATE - o.last_order_date) > 45 THEN 'At Risk'
        ELSE 'Active'
    END AS churn_status
FROM raw.customers c
LEFT JOIN order_facts o ON o.customer_id = c.customer_id
ORDER BY days_since_last_order DESC NULLS FIRST;

-- Q2: Cancellation / return rate as an early churn signal, by customer
SELECT
    o.customer_id,
    COUNT(*) FILTER (WHERE o.order_status = 'completed') AS completed_orders,
    COUNT(*) FILTER (WHERE o.order_status IN ('cancelled', 'returned')) AS problem_orders,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE o.order_status IN ('cancelled', 'returned'))
        / NULLIF(COUNT(*), 0), 1
    ) AS problem_order_pct
FROM raw.orders o
GROUP BY o.customer_id
HAVING COUNT(*) FILTER (WHERE o.order_status IN ('cancelled', 'returned')) > 0
ORDER BY problem_order_pct DESC;

-- Q3: Month-over-month change in active customers (macro churn signal)
WITH monthly_active AS (
    SELECT
        date_trunc('month', order_date)::date AS month,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM raw.orders
    WHERE order_status = 'completed'
    GROUP BY 1
)
SELECT
    month,
    active_customers,
    LAG(active_customers) OVER (ORDER BY month) AS prev_month_active,
    active_customers - LAG(active_customers) OVER (ORDER BY month) AS net_change,
    ROUND(
        100.0 * (active_customers - LAG(active_customers) OVER (ORDER BY month))
        / NULLIF(LAG(active_customers) OVER (ORDER BY month), 0), 1
    ) AS pct_change
FROM monthly_active
ORDER BY month;
