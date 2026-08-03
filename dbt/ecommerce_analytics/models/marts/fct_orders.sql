with orders as (
    select * from {{ ref('stg_orders') }}
),

items as (
    select
        order_id,
        sum(quantity) as total_units,
        sum(line_revenue) as order_revenue
    from {{ ref('stg_order_items') }}
    group by order_id
)

select
    o.order_id,
    o.customer_id,
    o.order_date,
    o.order_status,
    o.payment_method,
    o.shipping_cost,
    o.is_completed,
    coalesce(i.total_units, 0) as total_units,
    coalesce(i.order_revenue, 0) as order_revenue,
    coalesce(i.order_revenue, 0) + o.shipping_cost as order_total
from orders o
left join items i on i.order_id = o.order_id
