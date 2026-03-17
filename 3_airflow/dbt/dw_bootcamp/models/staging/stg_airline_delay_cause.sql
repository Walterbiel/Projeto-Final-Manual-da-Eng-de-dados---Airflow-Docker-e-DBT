with src as (

    select
        year,
        month,
        carrier,
        carrier_name,
        airport,
        airport_name,
        arr_flights,
        arr_del15,
        carrier_ct,
        weather_ct,
        nas_ct,
        security_ct,
        late_aircraft_ct,
        arr_cancelled,
        arr_diverted,
        arr_delay,
        carrier_delay,
        weather_delay,
        nas_delay,
        security_delay,
        late_aircraft_delay
    from {{ ref('Airline_Delay_Cause') }}

),

typed as (

    select
        cast(year as integer)  as year,
        cast(month as integer) as month,

        cast(carrier as text)       as carrier,
        cast(carrier_name as text)  as carrier_name,

        cast(airport as text)       as airport,
        cast(airport_name as text)  as airport_name,

        cast(arr_flights as integer) as arr_flights,
        cast(arr_del15 as integer)   as arr_del15,

        cast(carrier_ct as numeric)       as carrier_ct,
        cast(weather_ct as numeric)       as weather_ct,
        cast(nas_ct as numeric)           as nas_ct,
        cast(security_ct as numeric)      as security_ct,
        cast(late_aircraft_ct as numeric) as late_aircraft_ct,

        cast(arr_cancelled as integer) as arr_cancelled,
        cast(arr_diverted as integer)  as arr_diverted,

        cast(arr_delay as integer)          as arr_delay,
        cast(carrier_delay as integer)      as carrier_delay,
        cast(weather_delay as integer)      as weather_delay,
        cast(nas_delay as integer)          as nas_delay,
        cast(security_delay as integer)     as security_delay,
        cast(late_aircraft_delay as integer) as late_aircraft_delay,

        (cast(year as integer) * 100 + cast(month as integer)) as year_month_key

    from src
)

select *
from typed
