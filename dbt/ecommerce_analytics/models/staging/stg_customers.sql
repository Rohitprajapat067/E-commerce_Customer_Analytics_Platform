with source as (
    select * from {{ source('raw', 'customers') }}
)

select
    customer_id,
    trim(first_name) as first_name,
    trim(last_name) as last_name,
    lower(trim(email)) as email,
    country,
    city,
    signup_date::date as signup_date,
    customer_segment
from source
