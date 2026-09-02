{{ config(materialized='table') }}

with spend as (
    select
        date,
        channel,
        spend,
        platform_reported_conversions
    from {{ ref('stg_ads_spend') }}
),

last_click_cash as (
    select
        order_date as date,
        last_click_channel as channel,
        sum(net_cash) as net_cash,
        sum(gross) as gross,
        count(*) as orders
    from {{ ref('stg_orders') }}
    group by 1, 2
),

company as (
    select
        order_date as date,
        sum(net_cash) as company_net_cash,
        sum(gross) as company_gross,
        count(*) as company_orders
    from {{ ref('stg_orders') }}
    group by 1
),

company_spend as (
    select
        date,
        sum(spend) as company_spend
    from spend
    group by 1
),

assumptions as (
    select
        max(case when assumption_key = 'break_even_mer' then assumption_value end) as break_even_mer,
        max(case when assumption_key = 'contribution_margin' then assumption_value end) as contribution_margin
    from {{ ref('stg_assumptions') }}
),

sessions as (
    select
        date,
        sessions,
        converting_sessions
    from {{ ref('stg_sessions') }}
)

select
    s.date,
    s.channel,
    round(s.spend, 2) as spend,
    round(coalesce(lc.net_cash, 0.0), 2) as net_cash,
    round(coalesce(lc.gross, 0.0), 2) as last_click_gross,
    coalesce(lc.orders, 0) as last_click_orders,
    case
        when s.spend = 0 then null
        else round(coalesce(lc.net_cash, 0.0) / s.spend, 4)
    end as mer,
    round(cs.company_spend, 2) as company_spend,
    round(co.company_net_cash, 2) as company_net_cash,
    case
        when cs.company_spend = 0 then null
        else round(co.company_net_cash / cs.company_spend, 4)
    end as company_mer,
    a.break_even_mer,
    a.contribution_margin,
    case
        when cs.company_spend = 0 then null
        when co.company_net_cash / cs.company_spend >= a.break_even_mer then 'above_break_even'
        else 'below_break_even'
    end as company_mer_vs_break_even,
    sess.sessions,
    sess.converting_sessions
from spend as s
left join last_click_cash as lc
    on s.date = lc.date
    and s.channel = lc.channel
left join company as co
    on s.date = co.date
left join company_spend as cs
    on s.date = cs.date
left join sessions as sess
    on s.date = sess.date
cross join assumptions as a
