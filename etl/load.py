"""Load step: writes DataFrames into the Postgres `raw` schema.

Supports two modes:
  - full_refresh (default): truncate + reload the table each run
  - incremental: append only rows newer than the max value of a
    watermark column already present in the target table (used for
    orders/order_items so repeated Airflow runs don't reprocess
    the full history).
"""
import os

import pandas as pd
from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine

from etl.logger import get_logger

logger = get_logger(__name__)


def get_engine() -> Engine:
    host = os.getenv("PG_HOST", "localhost")
    port = os.getenv("PG_PORT", "5432")
    db = os.getenv("PG_DB", "ecommerce_analytics")
    user = os.getenv("PG_USER", "analytics_user")
    password = os.getenv("PG_PASSWORD", "change_me")
    url = f"postgresql+psycopg2://{user}:{password}@{host}:{port}/{db}"
    return create_engine(url)


def load_table(
    engine: Engine,
    df: pd.DataFrame,
    table: str,
    schema: str = "raw",
    mode: str = "full_refresh",
    watermark_col: str | None = None,
) -> int:
    """Load a DataFrame into `schema.table`. Returns rows written."""
    if df.empty:
        logger.info("No rows to load for %s.%s", schema, table)
        return 0

    if mode == "incremental" and watermark_col:
        with engine.connect() as conn:
            exists = conn.execute(
                text(
                    "SELECT to_regclass(:full_name) IS NOT NULL"
                ),
                {"full_name": f"{schema}.{table}"},
            ).scalar()
            max_val = None
            if exists:
                max_val = conn.execute(
                    text(f"SELECT MAX({watermark_col}) FROM {schema}.{table}")
                ).scalar()
        if max_val is not None and watermark_col in df.columns:
            df = df[df[watermark_col] > pd.to_datetime(max_val)]
        logger.info(
            "Incremental load for %s.%s: %s new rows since %s",
            schema, table, len(df), max_val,
        )
        if df.empty:
            return 0
        df.to_sql(table, engine, schema=schema, if_exists="append", index=False)
        return len(df)

    # full_refresh: truncate (preserving the DDL-defined schema/constraints)
    # then append, falling back to a plain create-and-replace if the table
    # doesn't exist yet (e.g. running outside the provided schema.sql).
    with engine.connect() as conn:
        exists = conn.execute(
            text("SELECT to_regclass(:full_name) IS NOT NULL"),
            {"full_name": f"{schema}.{table}"},
        ).scalar()
        if exists:
            conn.execute(text(f"TRUNCATE TABLE {schema}.{table} CASCADE"))
            conn.commit()

    if_exists = "append" if exists else "replace"
    df.to_sql(table, engine, schema=schema, if_exists=if_exists, index=False)
    logger.info("Full refresh load for %s.%s: %s rows", schema, table, len(df))
    return len(df)
