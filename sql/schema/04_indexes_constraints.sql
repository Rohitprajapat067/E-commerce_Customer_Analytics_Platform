CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON raw.orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_order_date ON raw.orders(order_date);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON raw.order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON raw.order_items(product_id);
CREATE INDEX IF NOT EXISTS idx_customers_country ON raw.customers(country);
CREATE INDEX IF NOT EXISTS idx_products_category ON raw.products(category);

ALTER TABLE raw.customers ADD CONSTRAINT uq_customer_email UNIQUE (email);
