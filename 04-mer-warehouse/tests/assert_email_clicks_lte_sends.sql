-- Clicks cannot exceed sends.
select
    date,
    sends,
    clicks
from {{ ref('stg_email_sends') }}
where clicks > sends
