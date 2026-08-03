-- =====================================================================
-- RFM Analysis: Recency, Frequency, Monetary segmentation
-- =====================================================================

-- Q1: Raw R/F/M values per customer
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
    (CURRENT_DATE - MAX(order_date)) AS recency_days,
    COUNT(order_id) AS frequency,
    SUM(order_value) AS monetary
FROM order_facts
GROUP BY customer_id
ORDER BY monetary DESC;

-- Q2: RFM quartile scoring (1-4 for each dimension) + segment label
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
        (CURRENT_DATE - MAX(order_date)) AS recency_days,
        COUNT(order_id) AS frequency,
        SUM(order_value) AS monetary
    FROM order_facts
    GROUP BY customer_id
),
scored AS (
    SELECT
        customer_id, recency_days, frequency, monetary,
        NTILE(4) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(4) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(4) OVER (ORDER BY monetary ASC) AS m_score
    FROM customer_agg
)
SELECT
    customer_id, recency_days, frequency, monetary,
    r_score, f_score, m_score,
    (r_score + f_score + m_score) AS rfm_total,
    CASE
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 2 THEN 'Loyal Customers'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2 THEN 'Lost'
        ELSE 'Needs Attention'
    END AS rfm_segment
FROM scored
ORDER BY rfm_total DESC;

-- Q3: Customer count and average monetary value per RFM segment
-- (wrap Q2 as a CTE named rfm_segments in your BI tool / dbt model, then:)
-- SELECT rfm_segment, COUNT(*) AS customers, ROUND(AVG(monetary), 2) AS avg_monetary
-- FROM rfm_segments GROUP BY rfm_segment ORDER BY avg_monetary DESC;
