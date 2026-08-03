import os

from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker


def _database_url() -> str:
    host = os.getenv("PG_HOST", "localhost")
    port = os.getenv("PG_PORT", "5432")
    db = os.getenv("PG_DB", "ecommerce_analytics")
    user = os.getenv("PG_USER", "analytics_user")
    password = os.getenv("PG_PASSWORD", "change_me")
    return f"postgresql+psycopg2://{user}:{password}@{host}:{port}/{db}"


engine = create_engine(_database_url(), pool_pre_ping=True)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def run_query(sql: str, params: dict | None = None) -> list[dict]:
    """Run a read-only SQL query and return rows as a list of dicts."""
    with engine.connect() as conn:
        result = conn.execute(text(sql), params or {})
        columns = result.keys()
        return [dict(zip(columns, row)) for row in result.fetchall()]
