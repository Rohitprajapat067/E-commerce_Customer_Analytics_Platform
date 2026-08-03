"""Extract step: reads source CSVs into pandas DataFrames."""
from pathlib import Path

import pandas as pd

from etl.logger import get_logger

logger = get_logger(__name__)

DATA_DIR = Path(__file__).resolve().parent.parent / "data" / "raw"

TABLES = {
    "customers": "customers.csv",
    "products": "products.csv",
    "orders": "orders.csv",
    "order_items": "order_items.csv",
    "date_dim": "date_dim.csv",
}


def extract_all(data_dir: Path = DATA_DIR) -> dict[str, pd.DataFrame]:
    """Read every configured source CSV into a dict of DataFrames."""
    frames = {}
    for table, filename in TABLES.items():
        path = data_dir / filename
        if not path.exists():
            logger.warning("Source file missing, skipping: %s", path)
            continue
        df = pd.read_csv(path)
        logger.info("Extracted %s rows from %s", len(df), filename)
        frames[table] = df
    return frames
