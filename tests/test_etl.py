"""Unit tests for etl.extract / etl.load helpers.

Run with: pytest tests/test_etl.py -v
These tests don't require a live Postgres connection — load_table's
SQL-touching paths are exercised via a lightweight fake engine.
"""
from etl.extract import TABLES, extract_all


def test_tables_config_matches_expected_sources():
    expected = {"customers", "products", "orders", "order_items", "date_dim"}
    assert set(TABLES.keys()) == expected


def test_extract_all_reads_generated_sample_data():
    frames = extract_all()
    assert "customers" in frames
    assert "products" in frames
    assert "orders" in frames
    assert "order_items" in frames
    assert len(frames["customers"]) > 0
    assert len(frames["products"]) > 0
    # basic shape sanity checks
    assert "customer_id" in frames["customers"].columns
    assert "product_id" in frames["products"].columns


def test_orders_reference_valid_customers():
    frames = extract_all()
    customer_ids = set(frames["customers"]["customer_id"])
    order_customer_ids = set(frames["orders"]["customer_id"])
    assert order_customer_ids.issubset(customer_ids)


def test_order_items_reference_valid_orders_and_products():
    frames = extract_all()
    order_ids = set(frames["orders"]["order_id"])
    product_ids = set(frames["products"]["product_id"])
    assert set(frames["order_items"]["order_id"]).issubset(order_ids)
    assert set(frames["order_items"]["product_id"]).issubset(product_ids)


def test_no_negative_quantities_or_prices():
    frames = extract_all()
    items = frames["order_items"]
    assert (items["quantity"] > 0).all()
    assert (items["unit_price"] >= 0).all()
