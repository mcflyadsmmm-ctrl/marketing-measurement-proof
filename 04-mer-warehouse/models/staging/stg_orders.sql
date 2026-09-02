{{ config(materialized='view') }}

select
    order_id,
    order_date::date as order_date,
    gross::double as gross,
    returns::double as returns,
    net_cash::double as net_cash,
    last_click_channel
from {{ ref('orders') }}
