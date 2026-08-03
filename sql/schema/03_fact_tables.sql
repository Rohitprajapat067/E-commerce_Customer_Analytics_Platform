CREATE TABLE IF NOT EXISTS raw.orders (
    order_id        INTEGER PRIMARY KEY,
    customer_id     INTEGER NOT NULL REFERENCES raw.customers(customer_id),
    order_date      DATE NOT NULL,
    order_status    VARCHAR(50),
    payment_method  VARCHAR(50),
    shipping_cost   NUMERIC(10, 2) DEFAULT 0
);

CREATE TABLE IF NOT EXISTS raw.order_items (
    order_item_id   SERIAL PRIMARY KEY,
    order_id        INTEGER NOT NULL REFERENCES raw.orders(order_id),
    product_id      INTEGER NOT NULL REFERENCES raw.products(product_id),
    quantity        INTEGER NOT NULL CHECK (quantity > 0),
    unit_price      NUMERIC(10, 2) NOT NULL,
    discount_pct    NUMERIC(5, 2) DEFAULT 0
);
