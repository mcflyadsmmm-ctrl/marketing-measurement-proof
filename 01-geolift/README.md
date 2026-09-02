SAMPLE: GeoLift that recovers a known lift

Not Black Clover. Not Nutricost. Not client data. facebookincubator/GeoLift vignette panel (`GeoLift_PreTest` → `GeoTestData_PreTest`, `GeoLift_Test` → `GeoTestData_Test`). City names are the package’s. This folder does not invent DMAs.

Repo moved: `facebookexperimental/GeoLift` → [`facebookincubator/GeoLift`](https://github.com/facebookincubator/GeoLift) (API as of v2.7.5, January 2026).

## This Mac

R **4.6.1** is on this Mac. `Rscript R/run_geolift.R` still needs the GeoLift package (see install below):

```bash
cd 01-geolift
Rscript R/run_geolift.R
```

Target runtime: **under 20 minutes**. Small market grid (`N = 2,3`, four treatment periods, `lookback_window = 1`). Do not widen that grid in a screen.

## Install (once R exists)

In R, then the command above:

```r
install.packages(c("remotes", "ggplot2"), repos = "https://cloud.r-project.org")
if (!requireNamespace("augsynth", quietly = TRUE)) {
  tryCatch(
    install.packages("augsynth", repos = "https://cloud.r-project.org"),
    error = function(e) remotes::install_github("ebenmichael/augsynth")
  )
}
remotes::install_github("facebookincubator/GeoLift")
```

`R/run_geolift.R` runs the same installs if packages are missing.

## What it does

1. `GeoLiftMarketSelection()` — power + market ranking (supersedes `GeoLiftPowerFinder` / `GeoLiftPower.search`). Target: **5% MDE at ~80% power**. If a four-period window cannot, the brief says why and what unit budget / duration the ranking implies.
2. `GeoLiftPower()` — power curve for the chosen markets → `out/power.csv`.
3. Treatment vs control → `out/markets.csv`. Refuse a rank that is >40% of cash sales.
4. Copy the pre-test series. Inject **+8%** cash sales in treatment for **four periods** (`R/inject_lift.R`). Fit `GeoLift()` → `out/att.csv` (ATT, CI, p). If the CI misses 8%, the CMO brief says so. That is the point.
5. Charts titled **SAMPLE**. `out/CMO-brief.md` is scale / cut / rerun in cash-sales language.

Does **not** score the vignette’s baked-in Chicago/Portland 15-day campaign on `GeoTestData_Test`. Ground truth here is the +8% we inject.

Does **not** pause Amazon on the Recast OLS CSV. That design lives in `../00-recast-r-memo/out/experiment.md`. This folder is the GeoLift **method** (known-lift recovery). Recast’s loop is priors → interpret → validate; the live validate would be a geo panel for the freeze channel, not this vignette.

**Documented API check** (`R/run_documented.R`): Meta’s walkthrough `chicago` + `portland` on periods 91–105 **crashes** on augsynth 0.2.0 (`Yobs` 210 vs T=105). Do not invent that ATT. N=1 Milwaukee +8% inject **runs** without collapse (ATT 522, +10.5%, p=0.002). Interview ATT remains the collapsed three-city cell in `att.csv`.

GitHub Actions CI covers `00-recast-r-memo` only. GeoLift is too heavy for the runner.

## Interview

**Name one geo test:** markets from `out/markets.csv`, KPI = cash sales, result in `out/att.csv` and `out/CMO-brief.md`, what you cut in that brief (40% market, spillover, national TV, all-up Meta when the MMM splits ASC vs prospecting).

**Haus MSP:** `out/mmm-first-vs-geolift-first.md` — experiments **anchor** the response curve. Recast “validate the model” is the opposite sequencing.

**Identification (15 lines):** `out/identification.md`. GeoLift ATT on a geo-assignable holdout. Not national TV, not always-on brand you will not pause, not spillover. MTA is not incrementality.

## API

| Step | Function |
|---|---|
| Power + ranking | `GeoLiftMarketSelection()` |
| Power curve | `GeoLiftPower()` |
| Fit | `GeoLift(..., ConfidenceIntervals = TRUE)` |

If installed GeoLift is older and `GeoLiftMarketSelection` is missing, the script falls back to `GeoLiftPowerFinder` and writes that in the brief.
