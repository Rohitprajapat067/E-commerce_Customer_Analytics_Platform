from fastapi import FastAPI
from sqlalchemy import text

from api.database import engine
from api.routers import customers, kpi, products
from api.schemas import HealthCheck

app = FastAPI(
    title="E-commerce Customer Analytics API",
    description="KPI, RFM, CLV and product-performance endpoints backed by the analytics warehouse.",
    version="1.0.0",
)

app.include_router(kpi.router)
app.include_router(customers.router)
app.include_router(products.router)


@app.get("/", tags=["Health"])
def root():
    return {"message": "E-commerce Customer Analytics API. See /docs for Swagger UI."}


@app.get("/health", response_model=HealthCheck, tags=["Health"])
def health():
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        db_status = "connected"
    except Exception as exc:  # noqa: BLE001
        db_status = f"unavailable: {exc}"
    return {"status": "ok", "database": db_status}
