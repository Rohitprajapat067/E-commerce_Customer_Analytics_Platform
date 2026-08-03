from fastapi import APIRouter, Query

from api.database import run_query
from api.schemas import CustomerCLV, CustomerRFM

router = APIRouter(prefix="/customers", tags=["Customers"])


@router.get("/rfm", response_model=list[CustomerRFM])
def customer_rfm(limit: int = Query(50, ge=1, le=500)):
    """RFM segmentation per customer (Recency, Frequency, Monetary)."""
    sql = """
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
                customer_id,
                recency_days,
                frequency,
                monetary,
                NTILE(4) OVER (ORDER BY recency_days DESC) AS r_score,
                NTILE(4) OVER (ORDER BY frequency ASC) AS f_score,
                NTILE(4) OVER (ORDER BY monetary ASC) AS m_score
            FROM customer_agg
        )
        SELECT
            customer_id,
            recency_days,
            frequency,
            monetary,
            CASE
                WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Champions'
                WHEN r_score >= 3 AND f_score >= 2 THEN 'Loyal Customers'
                WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
                WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2 THEN 'Lost'
                ELSE 'Needs Attention'
            END AS rfm_segment
        FROM scored
        ORDER BY monetary DESC
        LIMIT :limit;
    """
    return run_query(sql, {"limit": limit})


@router.get("/clv", response_model=list[CustomerCLV])
def customer_clv(limit: int = Query(50, ge=1, le=500)):
    """Simple historical Customer Lifetime Value per customer."""
    sql = """
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
            SUM(order_value) / NULLIF(COUNT(order_id), 0) AS avg_order_value,
            (MAX(order_date) - MIN(order_date)) AS customer_lifespan_days,
            SUM(order_value) * (1 + (MAX(order_date) - MIN(order_date)) / 365.0) AS estimated_clv
        FROM order_facts
        GROUP BY customer_id
        ORDER BY estimated_clv DESC
        LIMIT :limit;
    """
    return run_query(sql, {"limit": limit})
