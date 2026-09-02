{{ config(materialized='view') }}

select
    date::date as date,
    sends::integer as sends,
    clicks::integer as clicks,
    attributed_revenue::double as attributed_revenue,
    clicks::double / nullif(sends, 0) as ctr
from {{ ref('email_sends') }}
