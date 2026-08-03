with completed_orders as (
    select * from {{ ref('fct_orders') }}
    where is_completed
),

customer_agg as (
    select
        customer_id,
        sum(order_revenue) as total_revenue,
        count(order_id) as total_orders,
        (max(order_date) - min(order_date)) as lifespan_days
    from completed_orders
    group by customer_id
)

select
    customer_id,
    total_revenue,
    total_orders,
    round(total_revenue / nullif(total_orders, 0), 2) as avg_order_value,
    lifespan_days,
    round(
        total_orders::numeric / nullif(greatest(lifespan_days, 1) / 365.0, 0), 2
    ) as purchase_freq_per_year,
    round(
        (total_revenue / nullif(total_orders, 0))
        * (total_orders::numeric / nullif(greatest(lifespan_days, 1) / 365.0, 0))
    , 2) as estimated_annual_clv
from customer_agg
