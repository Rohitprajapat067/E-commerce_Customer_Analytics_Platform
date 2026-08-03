with products as (
    select * from {{ ref('stg_products') }}
),

sales as (
    select
        oi.product_id,
        sum(oi.quantity) as total_units_sold,
        sum(oi.line_revenue) as total_revenue
    from {{ ref('stg_order_items') }} oi
    join {{ ref('stg_orders') }} o on o.order_id = oi.order_id
    where o.is_completed
    group by oi.product_id
)

select
    p.product_id,
    p.product_name,
    p.category,
    p.sub_category,
    p.unit_price,
    p.unit_cost,
    p.unit_margin,
    coalesce(s.total_units_sold, 0) as total_units_sold,
    coalesce(s.total_revenue, 0) as total_revenue
from products p
left join sales s on s.product_id = p.product_id
