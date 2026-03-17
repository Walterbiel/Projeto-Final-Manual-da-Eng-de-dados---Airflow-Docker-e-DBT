with base as (
    select
        airport,
        airport_name
    from {{ ref('stg_airline_delay_cause') }}
)

select
    airport                              as airport_id,
    max(airport_name)                    as airport_name
from base
group by airport
