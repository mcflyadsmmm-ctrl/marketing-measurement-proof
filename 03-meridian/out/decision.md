# SAMPLE: Robyn vs Meridian — one budget decision

Public SAMPLE only. Meta Robyn `dt_simulated_weekly` and Google Meridian `national_media` are **different simulated worlds**. They are not McFly client runs. They are not Black Clover or Nutricost. No ROI from those desks belongs here.

**Status (1 Sep 2026 evening):** R 4.6.1, Robyn 3.12.1, Nevergrad 1.0.12 (Python 3.9 `r-reticulate`), and google-meridian 1.8.0 (Python 3.11 `03-meridian/.venv`) are **installed**. Allocator and Meridian MCMC have **not** been run. There are **no** current-vs-recommended dollars to compare. This memo is the decision rule that still holds when both libraries finish and disagree. Do not invent those dollars.

---

## Do they want money in the same channel?

**Unknown until both runners write artifacts.** Different SAMPLE datasets cannot be lined up channel-for-channel. When both have run, compare Robyn `out/allocator_current_vs_recommended.csv` to Meridian `out/budget_reallocation.csv`. If the channel that **gains** spend is not the same in both, they disagree. Do not average the two mix recommendations.

---

## Decision framework (what wins when they disagree)

Rank the evidence. Do not blend it.

1. **Geo test (Project `01-geolift`) wins.** Cash-sales ATT and 95% CI on the disputed channel beat any national MMM coefficient. Incrementality is identified by design (treatment vs control markets). MMM is not.
2. **Identifiability next.** A high-spend, always-on, low-incremental channel is the usual fight. National weeks collinear with sales cannot separate that channel from base. Saturation curves and Bayesian posteriors do not fix that. If the channel is unidentified, freeze it.
3. **Priors next.** Meridian’s ROI prior (`LogNormal` on paid media in the Getting Started spec) is a statement of belief. Robyn Nevergrad without a lift/geo calibration is a search. A prior that contradicts a geo test is discarded. A Nevergrad winner that contradicts a geo test is discarded.
4. **Holdout MAPE last, and only as a veto.** Last-10-week MAPE can kill a model you would otherwise ship. It cannot tell you whether TV (or Channel0) caused sales. A better MAPE is not permission to move the disputed channel.

**Default side if Robyn Allocator and Meridian posterior conflict on a high-spend, low-incremental channel:** trust the geo test, freeze that channel’s MMM coefficient, do not average the two allocators.

Until the geo test exists, the operational mix on that channel is **current spend**. Neither library gets to reallocate it.

---

## Four sentences for a CFO

1. Do not average two MMMs to look decisive.
2. If Robyn’s Allocator and Meridian’s posterior disagree on a high-spend channel that both call weakly incremental, freeze that channel and do not spend either recommendation.
3. The tie-breaker is a geo test on cash sales, not holdout MAPE and not a blended prior.
4. After the geo ATT lands, lock that channel’s MMM coefficient to the geo-implied return and only then let the remaining mix move.

---

## What geo test settles it

**Design (Project `01-geolift`, Meta GeoLift package data — not invented DMAs):**

- **Question:** On the disputed high-spend / low-incremental channel, is cash sales incremental at the planned spend, or is the MMM fitting base as media?
- **KPI:** cash sales. Not platform ROAS, not conversions the pixel claimed.
- **Markets:** `GeoLiftMarketSelection()` targeting about a **5% MDE at ~80% power**. Refuse a design where treatment and control share overlapping media, or where one market is ~40% of sales.
- **Runtime:** `GeoLift()` on the selected markets. The SAMPLE recovery check in that folder injects **+8%** in treatment for T1–T4; report ATT, CI, and p, and say so if the CI misses 8%.
- **Decision rule:**
  - CI includes zero → freeze spend; freeze the MMM coefficient on that channel in **both** Robyn and Meridian; do not let Allocator or `BudgetOptimizer` move it.
  - ATT clearly above zero → set that channel’s coefficient / ROI prior to the geo-implied return; re-run allocation with the channel **locked**; throw out the other model’s recommendation on that channel.
  - ATT clearly below zero or CI below the spend hurdle → cut. The geo test overrules the MMM that wanted to scale it.

National TV, always-on brand, and spillover across markets are **not** identified by this geo test. Those stay frozen until the design matches the channel.

---

## What this folder will not say

- It will not say the two libraries “both add value” as a substitute for a pick.
- It will not put SAMPLE Allocator or Meridian ROI onto a W-2 brand.
- It will not imply McFly clients ran Meridian.
