with fct as (
    select * from {{ ref('int_fct_flight_delays') }}
),

by_month as (
    select
        month_id,
        sum(arr_delay)             as total_delay,
        sum(carrier_delay)         as carrier_delay,
        sum(weather_delay)         as weather_delay,
        sum(nas_delay)             as nas_delay,
        sum(security_delay)        as security_delay,
        sum(late_aircraft_delay)   as late_aircraft_delay
    from fct
    group by 1
)

select
    month_id,
    total_delay,

    case when total_delay = 0 then 0 else 1.0 * carrier_delay / total_delay end       as pct_carrier,
    case when total_delay = 0 then 0 else 1.0 * weather_delay / total_delay end       as pct_weather,
    case when total_delay = 0 then 0 else 1.0 * nas_delay / total_delay end           as pct_nas,
    case when total_delay = 0 then 0 else 1.0 * security_delay / total_delay end      as pct_security,
    case when total_delay = 0 then 0 else 1.0 * late_aircraft_delay / total_delay end as pct_late_aircraft

from by_month
