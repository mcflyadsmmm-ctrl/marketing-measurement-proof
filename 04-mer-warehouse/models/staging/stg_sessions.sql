{{ config(materialized='view') }}

select
    date::date as date,
    sessions::integer as sessions,
    converting_sessions::integer as converting_sessions,
    converting_sessions::double / nullif(sessions, 0) as session_cvr
from {{ ref('sessions') }}
