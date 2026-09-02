-- SAMPLE: incremental conversion rate on the clean holdout (DuckDB).
-- Reproduce from 05-hightouch-eda/:
--   ../.venv/bin/python -c "import duckdb; print(duckdb.sql(open('sql/incremental_cr.sql').read()))"
-- Treated = holdout_flag 0. Holdout = holdout_flag 1.
-- Incremental CR = treated CR − holdout CR (ITT, not sent vs unsent).

WITH base AS (
    SELECT
        holdout_flag,
        COUNT(*) AS n,
        SUM(converted) AS conversions,
        AVG(converted) AS cr
    FROM read_csv_auto('data/sends.csv')
    GROUP BY holdout_flag
),
pivoted AS (
    SELECT
        MAX(CASE WHEN holdout_flag = 0 THEN n END) AS treated_n,
        MAX(CASE WHEN holdout_flag = 1 THEN n END) AS holdout_n,
        MAX(CASE WHEN holdout_flag = 0 THEN conversions END) AS treated_conversions,
        MAX(CASE WHEN holdout_flag = 1 THEN conversions END) AS holdout_conversions,
        MAX(CASE WHEN holdout_flag = 0 THEN cr END) AS treated_cr,
        MAX(CASE WHEN holdout_flag = 1 THEN cr END) AS holdout_cr
    FROM base
)
SELECT
    treated_n,
    holdout_n,
    treated_conversions,
    holdout_conversions,
    treated_cr,
    holdout_cr,
    treated_cr - holdout_cr AS incremental_cr
FROM pivoted;
