"""
Generates synthetic e-commerce sample data into data/raw/*.csv.
No external dependencies beyond the Python standard library, so it
runs anywhere without a pip install.

Usage:
    python data/generate_sample_data.py
"""
import csv
import random
from datetime import date, timedelta
from pathlib import Path

random.seed(42)

OUT_DIR = Path(__file__).parent / "raw"
OUT_DIR.mkdir(parents=True, exist_ok=True)

N_CUSTOMERS = 500
N_PRODUCTS = 120
N_ORDERS = 4000
START_DATE = date(2024, 1, 1)
END_DATE = date(2026, 7, 31)

FIRST_NAMES = ["Aria", "Liam", "Noor", "Ivan", "Sara", "Omar", "Maya", "Leo",
               "Zoe", "Kabir", "Elena", "Diego", "Mei", "Yusuf", "Nina", "Arjun"]
LAST_NAMES = ["Khan", "Smith", "Garcia", "Chen", "Patel", "Novak", "Silva",
              "Kim", "Ali", "Rossi", "Muller", "Ivanov", "Lopez", "Sato"]
COUNTRIES = ["India", "United States", "United Kingdom", "Germany", "Brazil",
             "UAE", "Canada", "France", "Japan", "Australia"]
SEGMENTS = ["New", "Returning", "VIP", "At Risk"]

CATEGORIES = {
    "Electronics": ["Headphones", "Smartphones", "Laptops", "Cameras"],
    "Apparel": ["Men's Wear", "Women's Wear", "Footwear", "Accessories"],
    "Home": ["Kitchen", "Furniture", "Decor", "Bedding"],
    "Beauty": ["Skincare", "Makeup", "Haircare"],
    "Sports": ["Fitness", "Outdoor", "Team Sports"],
}

ORDER_STATUSES = ["completed", "completed", "completed", "cancelled", "returned"]
PAYMENT_METHODS = ["credit_card", "debit_card", "paypal", "upi", "cod"]


def random_date(start: date, end: date) -> date:
    delta = (end - start).days
    return start + timedelta(days=random.randint(0, delta))


def gen_customers():
    rows = []
    for cid in range(1, N_CUSTOMERS + 1):
        fn, ln = random.choice(FIRST_NAMES), random.choice(LAST_NAMES)
        rows.append({
            "customer_id": cid,
            "first_name": fn,
            "last_name": ln,
            "email": f"{fn.lower()}.{ln.lower()}{cid}@example.com",
            "country": random.choice(COUNTRIES),
            "city": random.choice(["Metro City", "Riverside", "Lakeview", "Hillside", "Downtown"]),
            "signup_date": random_date(START_DATE, END_DATE).isoformat(),
            "customer_segment": random.choice(SEGMENTS),
        })
    return rows


def gen_products():
    rows = []
    pid = 1
    for category, subcats in CATEGORIES.items():
        for _ in range(N_PRODUCTS // len(CATEGORIES)):
            sub = random.choice(subcats)
            cost = round(random.uniform(5, 300), 2)
            rows.append({
                "product_id": pid,
                "product_name": f"{sub} Item {pid}",
                "category": category,
                "sub_category": sub,
                "unit_price": round(cost * random.uniform(1.3, 2.2), 2),
                "unit_cost": cost,
            })
            pid += 1
    return rows


def gen_orders_and_items(customers, products):
    orders, items = [], []
    item_id = 1
    for oid in range(1, N_ORDERS + 1):
        cust = random.choice(customers)
        odate = random_date(
            date.fromisoformat(cust["signup_date"]), END_DATE
        )
        status = random.choice(ORDER_STATUSES)
        orders.append({
            "order_id": oid,
            "customer_id": cust["customer_id"],
            "order_date": odate.isoformat(),
            "order_status": status,
            "payment_method": random.choice(PAYMENT_METHODS),
            "shipping_cost": round(random.uniform(0, 15), 2),
        })
        for _ in range(random.randint(1, 5)):
            prod = random.choice(products)
            items.append({
                "order_item_id": item_id,
                "order_id": oid,
                "product_id": prod["product_id"],
                "quantity": random.randint(1, 4),
                "unit_price": prod["unit_price"],
                "discount_pct": random.choice([0, 0, 0, 5, 10, 15, 20]),
            })
            item_id += 1
    return orders, items


def gen_date_dim():
    rows = []
    d = START_DATE
    while d <= END_DATE:
        rows.append({
            "date_key": d.isoformat(),
            "year": d.year,
            "quarter": (d.month - 1) // 3 + 1,
            "month": d.month,
            "month_name": d.strftime("%B"),
            "day": d.day,
            "day_of_week": d.isoweekday(),
            "day_name": d.strftime("%A"),
            "is_weekend": d.isoweekday() in (6, 7),
        })
        d += timedelta(days=1)
    return rows


def write_csv(path: Path, rows: list[dict]):
    if not rows:
        return
    with open(path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=rows[0].keys())
        writer.writeheader()
        writer.writerows(rows)
    print(f"wrote {len(rows):>6} rows -> {path}")


if __name__ == "__main__":
    customers = gen_customers()
    products = gen_products()
    orders, items = gen_orders_and_items(customers, products)
    date_dim = gen_date_dim()

    write_csv(OUT_DIR / "customers.csv", customers)
    write_csv(OUT_DIR / "products.csv", products)
    write_csv(OUT_DIR / "orders.csv", orders)
    write_csv(OUT_DIR / "order_items.csv", items)
    write_csv(OUT_DIR / "date_dim.csv", date_dim)
