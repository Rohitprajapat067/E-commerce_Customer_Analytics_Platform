from fastapi import APIRouter, Query

from api.database import run_query
from api.schemas import ProductPerformance

router = APIRouter(prefix="/products", tags=["Products"])


@router.get("/performance", response_model=list[ProductPerformance])
def product_performance(limit: int = Query(20, ge=1, le=200)):
    """Top products by revenue."""
    sql = """
        SELECT
            p.product_id,
            p.product_name,
            p.category,
            SUM(oi.quantity) AS total_units_sold,
            SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100.0)) AS total_revenue
        FROM raw.order_items oi
        JOIN raw.products p ON p.product_id = oi.product_id
        JOIN raw.orders o ON o.order_id = oi.order_id
        WHERE o.order_status = 'completed'
        GROUP BY p.product_id, p.product_name, p.category
        ORDER BY total_revenue DESC
        LIMIT :limit;
    """
    return run_query(sql, {"limit": limit})
