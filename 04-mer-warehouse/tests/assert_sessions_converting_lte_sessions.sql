-- Converting sessions cannot exceed sessions.
select
    date,
    sessions,
    converting_sessions
from {{ ref('stg_sessions') }}
where converting_sessions > sessions
