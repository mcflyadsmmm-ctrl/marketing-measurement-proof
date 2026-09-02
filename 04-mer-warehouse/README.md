# SAMPLE: cash MER warehouse

Cash MER is **net_cash / spend**: order dollars after returns, divided by media spend. Break-even MER is **1 / contribution_margin** from `seeds/assumptions.csv` (SAMPLE 0.40 contribution → **2.50** break-even). That is the cash MER at which contribution covers media. It is **not** platform ROAS, not pixel conversions × AOV, and not Klaviyo last-click `attributed_revenue`. Those stack and double-count the same orders.

Public SAMPLE for Marty Smithson’s measurement hunt. **Not** Black Clover. **Not** Nutricost. **Not** W-2 numbers. No Snowflake required.

Unlocks: **Lola** (standardize metric definitions, reporting backbone), **Mozilla** (scalable staging → marts), **Hightouch** (warehouse SQL).

## Models

| Model | Grain | Point |
|---|---|---|
| `fct_daily_mer` | date × paid channel | Last-click `net_cash / spend` plus **company_mer** vs SAMPLE break-even 2.50 |
| `fct_channel_claimed_vs_cash` | channel (paid + Email) | Platform conversions × SAMPLE AOV (and email last-click) vs company `net_cash`. **Stacked claimed > cash.** |
| `dim_metric_dictionary` | one row per KPI | English definition, grain, and why not to trust platform ROAS |

Staging: `stg_ads_spend`, `stg_orders`, `stg_sessions`, `stg_email_sends`, `stg_assumptions`.

## Run (Python 3.9.6)

From this folder, using the repo venv (`../.venv`, dbt-core 1.7.x + dbt-duckdb + duckdb + pandas):

```bash
make build
```

`make build` runs `dbt build --profiles-dir .` when dbt is present, then exports `out/preview.csv`. If dbt is missing or fails, `python run_build.py` loads the same seeds, runs the same SQL on a local DuckDB file (`mer_warehouse.duckdb` in this folder, not `~/.dbt`), asserts tests, and writes the preview. Runtime is under a minute on a laptop.

```bash
../.venv/bin/python generate_seeds.py   # RNG seed 2020
../.venv/bin/python run_build.py        # DuckDB path; no dbt required
../.venv/bin/dbt build --profiles-dir . # optional; same models
```

`make dag` is the one-liner an Airflow BashOperator would call (`make build`). This repo does **not** stand up Airflow.

## Tests

- `not_null` on keys (date, channel, spend, net_cash, kpi_name)
- `accepted_values` on paid channel: Google, Meta, TikTok, Microsoft
- `net_cash <= gross` (singular test on orders)
- sessions converting ≤ sessions; email clicks ≤ sends; unique date × channel on spend

## Seeds (generated, seed=2020)

- `ads_spend_daily` — date × Google / Meta / TikTok / Microsoft, spend + platform_reported_conversions (pixels overlap)
- `orders` — order_id, gross, returns, net_cash, last_click_channel (a **partition**; pixels are not)
- `sessions` — date, sessions, converting_sessions
- `email_sends` — date, sends, clicks, attributed_revenue (last-click; distrust)
- `assumptions.csv` — SAMPLE `contribution_margin` 0.40 and `break_even_mer` 2.50, not a W-2 margin

## Lesson in `out/preview.csv`

Each paid channel claims a slice of *all* orders (plus view-through). Email last-click attributed_revenue is inflated on top. **Sum of `claimed_revenue` exceeds company `net_cash`.** Channel ROAS that you add together is not cash MER.

## Interview lines

- Lola: definitions live in `dim_metric_dictionary`; the backbone is staging → marts, not a spreadsheet.
- Mozilla: same grain and tests you would scale; DuckDB here so a clone does not need Snowflake.
- Hightouch: the claimed-vs-cash SQL is the warehouse conversation — counterfactual cash vs platform credit.
