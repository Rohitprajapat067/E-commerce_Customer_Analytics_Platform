"""
End-to-end ETL entrypoint: extract source CSVs -> load into
Postgres `raw` schema (Bronze layer).

Usage:
    python -m etl.run_etl
"""
from etl.extract import extract_all
from etl.load import get_engine, load_table
from etl.logger import get_logger

logger = get_logger(__name__)

# order matters: parents (customers, products, date_dim) before children
# (orders, order_items) so that foreign key constraints hold.
LOAD_ORDER = ["customers", "products", "date_dim", "orders", "order_items"]

# tables loaded incrementally on repeat runs, keyed by their watermark column
INCREMENTAL = {
    "orders": "order_date",
}


def main():
    logger.info("Starting ETL run")
    frames = extract_all()
    engine = get_engine()

    total_rows = 0
    for table in LOAD_ORDER:
        if table not in frames:
            continue
        df = frames[table]
        watermark = INCREMENTAL.get(table)
        mode = "incremental" if watermark else "full_refresh"
        rows = load_table(engine, df, table, mode=mode, watermark_col=watermark)
        total_rows += rows

    logger.info("ETL run complete. Total rows loaded: %s", total_rows)


if __name__ == "__main__":
    main()
