-- =====================================================================
-- Advanced SQL / Window Function Examples
-- =====================================================================

-- Q1: Running total of daily revenue
WITH daily AS (
    SELECT o.order_date,
           SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100.0)) AS revenue
    FROM raw.orders o
    JOIN raw.order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'completed'
    GROUP BY o.order_date
)
SELECT
    order_date,
    revenue,
    ROUND(SUM(revenue) OVER (ORDER BY order_date), 2) AS running_total_revenue,
    ROUND(AVG(revenue) OVER (ORDER BY order_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2) AS revenue_7d_moving_avg
FROM daily
ORDER BY order_date;

-- Q2: Rank customers by spend within each country (partitioned ranking)
WITH order_facts AS (
    SELECT o.customer_id, o.customer_country, SUM(v.order_value) AS total_spend
    FROM (
        SELECT o.order_id, o.customer_id, c.country AS customer_country,
               SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100.0)) AS order_value
        FROM raw.orders o
        JOIN raw.order_items oi ON oi.order_id = o.order_id
        JOIN raw.customers c ON c.customer_id = o.customer_id
        WHERE o.order_status = 'completed'
        GROUP BY o.order_id, o.customer_id, c.country
    ) v
    JOIN raw.orders o ON o.order_id = v.order_id
    GROUP BY o.customer_id, v.customer_country
)
SELECT
    customer_id,
    customer_country,
    total_spend,
    RANK() OVER (PARTITION BY customer_country ORDER BY total_spend DESC) AS rank_in_country,
    ROUND(PERCENT_RANK() OVER (PARTITION BY customer_country ORDER BY total_spend), 3) AS percentile_in_country
FROM order_facts
ORDER BY customer_country, rank_in_country;

-- Q3: First purchase vs. repeat purchase flag using LAG/ROW_NUMBER
SELECT
    customer_id,
    order_id,
    order_date,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) AS order_sequence,
    LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS previous_order_date,
    order_date - LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS days_since_previous_order
FROM raw.orders
WHERE order_status = 'completed'
ORDER BY customer_id, order_date;

-- Q4: Top 3 products per category by revenue (window + filter pattern)
WITH product_revenue AS (
    SELECT
        p.category,
        p.product_id,
        p.product_name,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100.0)) AS revenue
    FROM raw.order_items oi
    JOIN raw.products p ON p.product_id = oi.product_id
    JOIN raw.orders o ON o.order_id = oi.order_id
    WHERE o.order_status = 'completed'
    GROUP BY p.category, p.product_id, p.product_name
),
ranked AS (
    SELECT *, DENSE_RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS category_rank
    FROM product_revenue
)
SELECT category, product_id, product_name, revenue, category_rank
FROM ranked
WHERE category_rank <= 3
ORDER BY category, category_rank;

-- Q5: New vs. returning customer revenue split per month
WITH first_orders AS (
    SELECT customer_id, MIN(order_date) AS first_order_date
    FROM raw.orders
    WHERE order_status = 'completed'
    GROUP BY customer_id
),
order_value AS (
    SELECT o.order_id, o.customer_id, o.order_date,
           SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100.0)) AS order_value
    FROM raw.orders o
    JOIN raw.order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'completed'
    GROUP BY o.order_id, o.customer_id, o.order_date
)
SELECT
    date_trunc('month', ov.order_date)::date AS month,
    CASE WHEN ov.order_date = fo.first_order_date THEN 'New' ELSE 'Returning' END AS customer_type,
    ROUND(SUM(ov.order_value), 2) AS revenue
FROM order_value ov
JOIN first_orders fo ON fo.customer_id = ov.customer_id
GROUP BY 1, 2
ORDER BY 1, 2;
