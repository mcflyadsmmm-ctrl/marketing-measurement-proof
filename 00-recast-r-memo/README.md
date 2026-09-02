SAMPLE: Recast-style R pipeline (lm + geometric adstock). Not a ~30k-parameter Bayesian MMM. Not Robyn. Not a client.

# Recast take-home muscle

Answers the [Marketing Data Scientist posting](https://job-boards.greenhouse.io/recast/jobs/4032276008): R pipelines, set priors with clients, interpret results, plan experiments to validate the model. Take-home is 1–2 days. Recast’s product is a large Bayesian MMM; this folder is the **client-facing loop**, not a clone.

**Interview line:** I set priors in English, I do not treat platform conversions as the KPI, and I will not move budget until a geo test validates the weakest channel.

## Run

R **4.6.1** is installed on this Mac. From this folder:

```r
install.packages(c("dplyr", "readr", "ggplot2", "broom", "lubridate", "tibble", "tidyr"), repos = "https://cloud.r-project.org")
```

`R/run.R` installs those three from `https://cloud.r-project.org` if they are missing.

```bash
cd 00-recast-r-memo
Rscript R/run.R
```

**Runtime:** first package install a few minutes; after that **under 30 seconds** (OLS on 91 weeks). Optional `brms` is not used. Does not require the full tidyverse meta-package.

**Outputs:** `out/CMO-memo.md` (≤ 800 words, numbers from `broom::tidy`), `out/priors.md`, `out/experiment.md`, PNGs titled `SAMPLE: ...`, plus `out/tidy.csv`, `out/vif.csv`, `out/theta_grid.csv`.

VIF is computed with base-R auxiliary regressions (`car` is not required).

## Data

`data/sample_weekly.csv` is generated if missing (`set.seed(2020)`). 104 weeks starting Monday **2023-01-02**.

Columns: `week`, `spend_google`, `spend_meta`, `spend_tiktok`, `spend_amazon`, `promo_flag`, `cash_sales`, `platform_reported_conversions`.

TikTok weeks 1–2 are `NA` in the export (not launched; imputed to 0 before adstock). Week 1 platform conversions are `NA` (pixel not live). Promo flag is 1 on a few sale / BFCM-ish Mondays. TikTok ramps. Spend is weekly USD with seasonality and Q4 lift.

## Known DGP (reviewer only — not the CMO memo)

Geometric adstock: `s[1] = x[1]`; `s[t] = x[t] + θ · s[t−1]`.

True θ: Google 0.50, Meta 0.50, TikTok 0.45, Amazon 0.40.

```
cash_sales = 78000
           + 1.55 * ads_google
           + 2.05 * ads_meta
           + 0.32 * ads_tiktok
           + 0.88 * ads_amazon
           + 14000 * promo_flag
           + N(0, 4500)
```

AOV **$68**. Platform conversions **double-count**: Google and Meta both claim overlapping cash, so `platform_reported_conversions` is inflated versus `cash_sales / 68`. The pipeline prints that correlation and the inflation ratio — they will not match.

Do **not** paste these true betas into the CMO memo as if they were estimated. The memo interpolates from the fit.

## Model

1. Missingness, spend share, `cor(platform conversions, cash_sales)`.
2. Shared θ grid `{0.3, 0.5, 0.7}`; pick by holdout **weeks 92–104** RMSE on `cash_sales`.
3. `cash_sales ~ adstocked spends + promo` on weeks 1–91. `broom::tidy` 95% CI. VIF table.
4. English **PRIORS** per channel (operator experience, labeled prior, not data).
5. 4-week GeoLift **design** on the widest-CI channel (markets, KPI = cash sales, success = CI excludes 0). GeoLift is not run here.
6. CMO memo: cut / hold / scale from the fit. What we will not do until the geo test.

## What this is not

- Not Recast’s production model.
- Not Meta Robyn (that is a different folder).
- Not a W-2 account and not live ad-account extracts.
