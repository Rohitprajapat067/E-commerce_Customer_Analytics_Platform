with customers as (
    select * from {{ ref('stg_customers') }}
),

order_stats as (
    select
        o.customer_id,
        count(distinct o.order_id) filter (where o.is_completed) as total_orders,
        min(o.order_date) filter (where o.is_completed) as first_order_date,
        max(o.order_date) filter (where o.is_completed) as last_order_date,
        sum(oi.line_revenue) filter (where o.is_completed) as lifetime_revenue
    from {{ ref('stg_orders') }} o
    left join {{ ref('stg_order_items') }} oi on oi.order_id = o.order_id
    group by o.customer_id
)

select
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    c.country,
    c.city,
    c.signup_date,
    c.customer_segment,
    coalesce(s.total_orders, 0) as total_orders,
    s.first_order_date,
    s.last_order_date,
    coalesce(s.lifetime_revenue, 0) as lifetime_revenue,
    (current_date - s.last_order_date) as days_since_last_order
from customers c
left join order_stats s on s.customer_id = c.customer_id
