with fct as (
    select * from {{ ref('int_fct_flight_delays') }}
),

dim_month as (
    select * from {{ ref('int_dim_month') }}
)

select
    m.year,
    m.month,
    m.month_id,

    sum(f.arr_flights)                                 as flights,
    sum(f.arr_del15)                                   as delayed_15m,

    case when sum(f.arr_flights) = 0 then 0
         else 1.0 * sum(f.arr_del15) / sum(f.arr_flights)
    end                                                as pct_delayed_15m,

    sum(f.arr_cancelled)                               as cancelled,
    sum(f.arr_diverted)                                as diverted,

    sum(f.arr_delay)                                   as total_delay_minutes

from fct f
join dim_month m
  on f.month_id = m.month_id
group by 1,2,3
