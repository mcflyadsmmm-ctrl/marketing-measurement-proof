{{ config(materialized='view') }}

select
    assumption_key,
    assumption_value::double as assumption_value,
    unit,
    notes
from {{ ref('assumptions') }}
