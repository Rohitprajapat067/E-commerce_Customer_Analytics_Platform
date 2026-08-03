-- =====================================================================
-- Revenue / Order KPIs
-- =====================================================================

-- Q1: Headline KPIs
SELECT
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT o.customer_id) AS total_customers,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100.0)), 2) AS total_revenue,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100.0))
          / NULLIF(COUNT(DISTINCT o.order_id), 0), 2) AS average_order_value,
    ROUND(SUM(oi.quantity)::numeric / NULLIF(COUNT(DISTINCT o.order_id), 0), 2) AS avg_items_per_order
FROM raw.orders o
JOIN raw.order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'completed';

-- Q2: Revenue by category
SELECT
    p.category,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100.0)), 2) AS revenue,
    SUM(oi.quantity) AS units_sold
FROM raw.order_items oi
JOIN raw.products p ON p.product_id = oi.product_id
JOIN raw.orders o ON o.order_id = oi.order_id
WHERE o.order_status = 'completed'
GROUP BY p.category
ORDER BY revenue DESC;

-- Q3: Revenue by country
SELECT
    c.country,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100.0)), 2) AS revenue,
    COUNT(DISTINCT o.order_id) AS orders
FROM raw.orders o
JOIN raw.order_items oi ON oi.order_id = o.order_id
JOIN raw.customers c ON c.customer_id = o.customer_id
WHERE o.order_status = 'completed'
GROUP BY c.country
ORDER BY revenue DESC;

-- Q4: Payment method mix
SELECT
    payment_method,
    COUNT(*) AS orders,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_orders
FROM raw.orders
GROUP BY payment_method
ORDER BY orders DESC;

-- Q5: Order status breakdown (cancellation / return rate)
SELECT
    order_status,
    COUNT(*) AS orders,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_orders
FROM raw.orders
GROUP BY order_status
ORDER BY orders DESC;

-- Q6: Daily revenue trend (last 90 days)
SELECT
    o.order_date,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100.0)), 2) AS revenue
FROM raw.orders o
JOIN raw.order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'completed'
  AND o.order_date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY o.order_date
ORDER BY o.order_date;
