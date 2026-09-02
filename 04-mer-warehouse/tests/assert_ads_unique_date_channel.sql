-- Spend grain is one row per date x paid channel.
select
    date,
    channel,
    count(*) as n
from {{ ref('stg_ads_spend') }}
group by 1, 2
having count(*) > 1
