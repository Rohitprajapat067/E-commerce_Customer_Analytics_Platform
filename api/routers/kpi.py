from fastapi import APIRouter

from api.database import run_query
from api.schemas import MonthlyRevenue, RevenueKPI

router = APIRouter(prefix="/kpi", tags=["KPIs"])


@router.get("/revenue", response_model=RevenueKPI)
def revenue_summary():
    """Overall revenue KPIs computed from the raw layer (works even before dbt runs)."""
    sql = """
        SELECT
            COALESCE(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100.0)), 0) AS total_revenue,
            COUNT(DISTINCT o.order_id) AS total_orders,
            COALESCE(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100.0))
                     / NULLIF(COUNT(DISTINCT o.order_id), 0), 0) AS average_order_value,
            COUNT(DISTINCT o.customer_id) AS total_customers
        FROM raw.orders o
        JOIN raw.order_items oi ON oi.order_id = o.order_id
        WHERE o.order_status = 'completed';
    """
    rows = run_query(sql)
    return rows[0] if rows else {
        "total_revenue": 0, "total_orders": 0,
        "average_order_value": 0, "total_customers": 0,
    }


@router.get("/revenue/monthly", response_model=list[MonthlyRevenue])
def revenue_monthly():
    """Monthly revenue trend, most recent first."""
    sql = """
        SELECT
            date_trunc('month', o.order_date)::date AS month,
            SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100.0)) AS revenue,
            COUNT(DISTINCT o.order_id) AS order_count
        FROM raw.orders o
        JOIN raw.order_items oi ON oi.order_id = o.order_id
        WHERE o.order_status = 'completed'
        GROUP BY 1
        ORDER BY 1 DESC;
    """
    return run_query(sql)
