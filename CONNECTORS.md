# Connectors Marty has to click

Cursor cannot finish Recast or GeoLift without **R**. Cursor cannot put a public URL on LinkedIn without **you naming the GitHub account**. Nothing here needs Shopify, ads accounts, or Black Clover.

## Blocking tonight (Recast is apply-this-week)

### 1. R 4.6.1 for Apple Silicon

This Mac is **M4 / arm64**. There is **no Homebrew and no R**. Recast’s JD is R pipelines + a 1–2 day take-home. Project 0 is written in R on purpose.

1. Download [R-4.6.1-arm64.pkg](https://cran.r-project.org/bin/macosx/big-sur-arm64/base/R-4.6.1-arm64.pkg) from [CRAN macOS](https://cran.r-project.org/bin/macosx/).
2. Run the Apple installer (admin password). Custom install may omit Tcl/Tk and Texinfo.
3. Quit and reopen the terminal (or Cursor) so `Rscript` is on `PATH`.
4. Tell Cursor: **R is installed**. Then `Rscript 00-recast-r-memo/R/run.R` is the next command.

Until that pkg runs, Project 0 is source-complete and **not executed**.

### 2. Which GitHub account is public-proof?

`gh` is already logged in as **`mcflyadsmmm-ctrl`**. The packet identity is **Marty Smithson** (`linkedin.com/in/marty-smithson`). A McFly-branded GitHub on the Featured section fights the W-2 story.

Reply with one of:

- `mcflyadsmmm-ctrl` (ship now, McFly org in the URL), or
- a personal GitHub user you want `gh` switched to, then `gh repo create marketing-measurement-proof --public`.

Do not push until Project 0 has a green `Rscript` run (or you explicitly say push the source anyway).

### 3. GitHub MCP in Cursor (optional)

The GitHub plugin is in an error/auth state. `gh` already works. Only auth the MCP if you want PRs from chat. Not required to build.

## This machine (Cursor can do; no login)

Python **3.9.6**. Venv: `.venv/` in this repo.

```bash
.venv/bin/pip install -r requirements.txt
```

Need: `polars`, `duckdb`, `dbt-core<1.8`, `dbt-duckdb<1.8`, `pandas`, `numpy`, `matplotlib`, `statsmodels`. Jupyter optional.

## Later (Lola pulse only — not Recast)

| Connector | Why | When |
|---|---|---|
| **Tableau Public** account | Lola JD names Looker/Tableau, not Studio. Public workbook on SAMPLE CSV. | After warehouse seeds exist |
| **Looker trial** (Looker, not Looker Studio) | Same JD. One screenshot labeled Looker. | If you would rather show Looker than Tableau |
| Google Cloud / BigQuery sandbox | Optional second target for `google_analytics_sample`. DuckDB is enough to clone. | Only if a JD asks to see BQ |

## Never connect (would leak W-2 or look like a buyer seat)

- Shopify admin, Klaviyo, Meta Ads, Google Ads, Amazon Ads, TikTok Ads
- Snowflake / NetSuite / Black Clover / Nutricost extracts
- Recast / Haus / Meridian customer tenants
- Any file with live revenue

Public SAMPLE generators only.

## After R is installed — R packages (no extra accounts)

```r
install.packages(c("tidyverse", "lubridate", "broom", "remotes"), repos = "https://cloud.r-project.org")
# GeoLift:
install.packages("augsynth")  # if CRAN still has it; else follow GeoLift README
remotes::install_github("facebookincubator/GeoLift")
# Robyn: follow facebookexperimental/Robyn README (nevergrad + extra deps)
# CausalImpact:
install.packages("CausalImpact")
```

Robyn and Meridian are **days 11–22**. Do not block Recast on them.
