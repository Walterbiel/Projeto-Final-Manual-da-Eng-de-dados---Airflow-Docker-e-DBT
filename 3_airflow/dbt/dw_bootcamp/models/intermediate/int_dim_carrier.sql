with base as (
    select
        carrier,
        carrier_name
    from {{ ref('stg_airline_delay_cause') }}
)

select
    carrier                              as carrier_id,
    max(carrier_name)                    as carrier_name
from base
group by carrier
