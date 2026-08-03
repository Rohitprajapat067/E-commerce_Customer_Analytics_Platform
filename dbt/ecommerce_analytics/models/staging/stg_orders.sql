with source as (
    select * from {{ source('raw', 'orders') }}
)

select
    order_id,
    customer_id,
    order_date::date as order_date,
    order_status,
    payment_method,
    shipping_cost::numeric(10, 2) as shipping_cost,
    (order_status = 'completed') as is_completed
from source
