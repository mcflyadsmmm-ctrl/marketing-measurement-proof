{{ config(materialized='view') }}

select
    date::date as date,
    channel,
    spend::double as spend,
    platform_reported_conversions::integer as platform_reported_conversions
from {{ ref('ads_spend_daily') }}
