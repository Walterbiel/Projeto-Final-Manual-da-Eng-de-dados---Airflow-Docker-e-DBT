with fct as (
    select * from {{ ref('int_fct_flight_delays') }}
),
dim_carrier as (
    select * from {{ ref('int_dim_carrier') }}
)

select
    c.carrier_id,
    c.carrier_name,

    sum(f.arr_flights) as flights,
    sum(f.arr_del15)   as delayed_15m,

    case when sum(f.arr_flights) = 0 then 0
         else 1.0 * sum(f.arr_del15) / sum(f.arr_flights)
    end                as pct_delayed_15m,

    sum(f.arr_cancelled) as cancelled,
    sum(f.arr_delay)     as total_delay_minutes

from fct f
join dim_carrier c
  on f.carrier_id = c.carrier_id
group by 1,2
