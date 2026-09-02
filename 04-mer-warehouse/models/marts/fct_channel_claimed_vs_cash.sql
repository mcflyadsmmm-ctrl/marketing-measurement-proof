{{ config(materialized='table') }}

with aov as (
    select
        max(case when assumption_key = 'aov' then assumption_value end) as aov,
        max(case when assumption_key = 'break_even_mer' then assumption_value end) as break_even_mer
    from {{ ref('stg_assumptions') }}
),

paid_claimed as (
    select
        channel,
        sum(spend) as spend,
        sum(platform_reported_conversions) as platform_reported_conversions,
        cast(null as double) as email_attributed_revenue
    from {{ ref('stg_ads_spend') }}
    group by 1
),

email_claimed as (
    select
        'Email' as channel,
        0.0 as spend,
        cast(null as integer) as platform_reported_conversions,
        sum(attributed_revenue) as email_attributed_revenue
    from {{ ref('stg_email_sends') }}
),

claimed as (
    select * from paid_claimed
    union all
    select * from email_claimed
),

last_click_cash as (
    select
        last_click_channel as channel,
        sum(net_cash) as last_click_net_cash
    from {{ ref('stg_orders') }}
    group by 1
),

company as (
    select sum(net_cash) as company_net_cash
    from {{ ref('stg_orders') }}
),

with_claimed as (
    select
        c.channel,
        c.spend,
        c.platform_reported_conversions,
        a.aov,
        case
            when c.channel = 'Email' then coalesce(c.email_attributed_revenue, 0.0)
            else coalesce(c.platform_reported_conversions, 0) * a.aov
        end as claimed_revenue,
        coalesce(lc.last_click_net_cash, 0.0) as last_click_net_cash,
        co.company_net_cash,
        a.break_even_mer
    from claimed as c
    cross join aov as a
    cross join company as co
    left join last_click_cash as lc
        on c.channel = lc.channel
)

select
    channel,
    round(spend, 2) as spend,
    platform_reported_conversions,
    aov,
    round(claimed_revenue, 2) as claimed_revenue,
    round(last_click_net_cash, 2) as last_click_net_cash,
    round(company_net_cash, 2) as company_net_cash,
    round(claimed_revenue - last_click_net_cash, 2) as claimed_minus_last_click_cash,
    round(claimed_revenue / nullif(company_net_cash, 0), 4) as claimed_share_of_company_cash,
    round(sum(claimed_revenue) over (), 2) as total_claimed_revenue,
    round(sum(claimed_revenue) over () / nullif(company_net_cash, 0), 4) as stack_claimed_to_cash_ratio,
    break_even_mer
from with_claimed
