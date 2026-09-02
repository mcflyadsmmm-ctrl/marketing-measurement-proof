-- net_cash must be <= gross on every order.
select
    order_id,
    gross,
    returns,
    net_cash
from {{ ref('stg_orders') }}
where net_cash > gross
