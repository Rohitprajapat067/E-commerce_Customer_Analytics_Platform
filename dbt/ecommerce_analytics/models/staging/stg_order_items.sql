with source as (
    select * from {{ source('raw', 'order_items') }}
)

select
    order_item_id,
    order_id,
    product_id,
    quantity,
    unit_price::numeric(10, 2) as unit_price,
    discount_pct::numeric(5, 2) as discount_pct,
    round((quantity * unit_price * (1 - discount_pct / 100.0))::numeric, 2) as line_revenue
from source
