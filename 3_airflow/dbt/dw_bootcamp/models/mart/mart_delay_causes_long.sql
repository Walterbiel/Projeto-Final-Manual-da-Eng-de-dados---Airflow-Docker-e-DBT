with fct as (
    select * from {{ ref('int_fct_flight_delays') }}
),

unpivoted as (

    select month_id, carrier_id, airport_id, 'carrier' as cause, carrier_delay as delay_minutes from fct
    union all
    select month_id, carrier_id, airport_id, 'weather' as cause, weather_delay as delay_minutes from fct
    union all
    select month_id, carrier_id, airport_id, 'nas' as cause, nas_delay as delay_minutes from fct
    union all
    select month_id, carrier_id, airport_id, 'security' as cause, security_delay as delay_minutes from fct
    union all
    select month_id, carrier_id, airport_id, 'late_aircraft' as cause, late_aircraft_delay as delay_minutes from fct

)

select * from unpivoted
