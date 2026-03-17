with stg as (
    select * from {{ ref('stg_airline_delay_cause') }}
),

fct as (
    select
        -- chaves do DW
        stg.year_month_key                       as month_id,
        stg.carrier                              as carrier_id,
        stg.airport                              as airport_id,

        -- métricas
        stg.arr_flights,
        stg.arr_del15,
        stg.arr_cancelled,
        stg.arr_diverted,

        -- atrasos (minutos)
        stg.arr_delay,
        stg.carrier_delay,
        stg.weather_delay,
        stg.nas_delay,
        stg.security_delay,
        stg.late_aircraft_delay,

        -- contagens por causa (ocorrências)
        stg.carrier_ct,
        stg.weather_ct,
        stg.nas_ct,
        stg.security_ct,
        stg.late_aircraft_ct

    from stg
)

select * from fct
