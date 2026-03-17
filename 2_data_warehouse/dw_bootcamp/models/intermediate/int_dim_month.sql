with base as (
    select distinct
        year,
        month,
        year_month_key
    from {{ ref('stg_airline_delay_cause') }}
)

select
    year_month_key                     as month_id,
    year,
    month
from base
