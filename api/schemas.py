from datetime import date

from pydantic import BaseModel


class RevenueKPI(BaseModel):
    total_revenue: float
    total_orders: int
    average_order_value: float
    total_customers: int


class MonthlyRevenue(BaseModel):
    month: date
    revenue: float
    order_count: int


class CustomerRFM(BaseModel):
    customer_id: int
    recency_days: int
    frequency: int
    monetary: float
    rfm_segment: str


class CustomerCLV(BaseModel):
    customer_id: int
    total_revenue: float
    total_orders: int
    avg_order_value: float
    customer_lifespan_days: int
    estimated_clv: float


class ProductPerformance(BaseModel):
    product_id: int
    product_name: str
    category: str
    total_units_sold: int
    total_revenue: float


class HealthCheck(BaseModel):
    status: str
    database: str
