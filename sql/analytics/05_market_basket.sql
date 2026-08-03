-- =====================================================================
-- Market Basket / Product Affinity Analysis
-- =====================================================================

-- Q1: Product pairs frequently bought together in the same order
WITH order_products AS (
    SELECT DISTINCT order_id, product_id
    FROM raw.order_items
)
SELECT
    a.product_id AS product_a,
    b.product_id AS product_b,
    COUNT(*) AS times_bought_together
FROM order_products a
JOIN order_products b
    ON a.order_id = b.order_id
    AND a.product_id < b.product_id
GROUP BY a.product_id, b.product_id
HAVING COUNT(*) >= 3
ORDER BY times_bought_together DESC
LIMIT 50;

-- Q2: Product pair affinity with names + simple "support" and "confidence"
WITH order_products AS (
    SELECT DISTINCT order_id, product_id FROM raw.order_items
),
pair_counts AS (
    SELECT a.product_id AS product_a, b.product_id AS product_b, COUNT(*) AS pair_count
    FROM order_products a
    JOIN order_products b ON a.order_id = b.order_id AND a.product_id < b.product_id
    GROUP BY a.product_id, b.product_id
),
product_order_counts AS (
    SELECT product_id, COUNT(DISTINCT order_id) AS order_count
    FROM order_products
    GROUP BY product_id
),
total_orders AS (
    SELECT COUNT(DISTINCT order_id) AS n FROM raw.orders
)
SELECT
    pa.product_name AS product_a_name,
    pb.product_name AS product_b_name,
    pc.pair_count,
    ROUND(pc.pair_count::numeric / t.n, 4) AS support,
    ROUND(pc.pair_count::numeric / NULLIF(oa.order_count, 0), 4) AS confidence_a_to_b
FROM pair_counts pc
JOIN raw.products pa ON pa.product_id = pc.product_a
JOIN raw.products pb ON pb.product_id = pc.product_b
JOIN product_order_counts oa ON oa.product_id = pc.product_a
CROSS JOIN total_orders t
WHERE pc.pair_count >= 3
ORDER BY pc.pair_count DESC
LIMIT 50;

-- Q3: Category-level co-purchase matrix (cross-category affinity)
WITH order_categories AS (
    SELECT DISTINCT oi.order_id, p.category
    FROM raw.order_items oi
    JOIN raw.products p ON p.product_id = oi.product_id
)
SELECT
    a.category AS category_a,
    b.category AS category_b,
    COUNT(*) AS co_occurrences
FROM order_categories a
JOIN order_categories b ON a.order_id = b.order_id AND a.category < b.category
GROUP BY a.category, b.category
ORDER BY co_occurrences DESC;
