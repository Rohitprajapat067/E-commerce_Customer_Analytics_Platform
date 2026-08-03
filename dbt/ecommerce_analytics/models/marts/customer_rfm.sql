with completed_orders as (
    select * from {{ ref('fct_orders') }}
    where is_completed
),

customer_agg as (
    select
        customer_id,
        (current_date - max(order_date)) as recency_days,
        count(order_id) as frequency,
        sum(order_revenue) as monetary
    from completed_orders
    group by customer_id
),

scored as (
    select
        customer_id,
        recency_days,
        frequency,
        monetary,
        ntile(4) over (order by recency_days desc) as r_score,
        ntile(4) over (order by frequency asc) as f_score,
        ntile(4) over (order by monetary asc) as m_score
    from customer_agg
)

select
    customer_id,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    (r_score + f_score + m_score) as rfm_total,
    case
        when r_score >= 3 and f_score >= 3 and m_score >= 3 then 'Champions'
        when r_score >= 3 and f_score >= 2 then 'Loyal Customers'
        when r_score <= 2 and f_score >= 3 then 'At Risk'
        when r_score <= 2 and f_score <= 2 and m_score <= 2 then 'Lost'
        else 'Needs Attention'
    end as rfm_segment
from scored
