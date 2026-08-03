with source as (
    select * from {{ source('raw', 'products') }}
)

select
    product_id,
    trim(product_name) as product_name,
    category,
    sub_category,
    unit_price::numeric(10, 2) as unit_price,
    unit_cost::numeric(10, 2) as unit_cost,
    round((unit_price - unit_cost)::numeric, 2) as unit_margin
from source
