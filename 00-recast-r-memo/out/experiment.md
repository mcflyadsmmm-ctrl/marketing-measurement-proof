# SAMPLE: 4-week GeoLift design (not a result)

This folder does **not** run GeoLift. This is the experiment we would take to a client after the OLS + adstock pass, matching Recast’s loop: priors → interpret → **validate**.

**Channel under test:** Amazon (widest 95% CI on adstocked spend).
**OLS we are validating:** $0.87 cash per adstocked dollar (95% CI $0.11 to $1.63). CI width $1.51.
**Adstock used in that fit:** geometric θ = 0.5 (shared across channels; selected on holdout RMSE).
**Training scale:** mean weekly Amazon spend $8,151; mean adstocked $16,127; OLS-implied mean weekly cash contribution $14,033 (not a causal ATT).
**In-sample R² (train):** 0.941. This is not the success metric of the test. It recovers this SAMPLE DGP; a live Recast client will not look like this.

## Hypothesis

If Amazon is incremental in cash, turning it off in treatment markets for four weeks will reduce cash sales relative to a synthetic control. The interval is the widest of the four paid channels. A pause asks whether the channel is incremental in cash; we are not trying to recover the OLS point estimate in four weeks.

## Treatment

- **Action:** pause Amazon (spend → $0) in treatment markets only.
- **What stays fixed:** national creative, site promo calendar, the other three paid channels’ bidding rules, and landing pages.
- **What we refuse:** a national budget change during the test; treating NYC and leaving Newark; using platform-reported conversions as the outcome.

## Markets (SAMPLE list — mid-size DMAs, not a power run)

**Treatment (8):** Indianapolis, Kansas City, Nashville, Milwaukee, Oklahoma City, Louisville, Raleigh-Durham, Austin.

**Donor pool (examples, not exhaustive):** Columbus, Cincinnati, Pittsburgh, Cleveland, St. Louis, Omaha, Des Moines, Tulsa, Birmingham, Memphis, Richmond, Norfolk, Jacksonville, Tampa, Orlando, Grand Rapids, Madison, Boise, Albuquerque, Tucson.

**Excluded on purpose:** New York, Los Angeles, Chicago, Dallas (too large a share of national cash; one market must not be ~40% of sales). Do not treat a DMA and leave its adjacent DMA in the donor pool (spillover).

This list is a **design on the OLS SAMPLE weeks**, not a power run and not a GeoLift result. Do not type NYC. Do not treat a DMA and leave its commute-shed in the donor pool.

## Sibling folder `01-geolift` (method, not this pause)

The executed SAMPLE GeoLift is a **known-lift recovery** on facebookincubator package data: Milwaukee / Orlando / Saint Paul, injected +8% on cash sales (column Y), 90% CI (`alpha = 0.1`), collapsed to one cell because augsynth 0.2.0 cannot fit N>1. That ATT is **not** an Amazon pause on this CSV. Recast onboard would run `GeoLiftMarketSelection` on the client’s geo panel for this channel, then pause. Charlie: read this design, then read `../01-geolift/out/CMO-brief.md` for the method check.

## Calendar

- **Pre-period:** 12 weeks of cash-sales matching before launch (synthetic control / augsynth-style).
- **Test window:** four consecutive weeks. SAMPLE dates if we ran it after this panel: **2025-01-06 through 2025-02-02** (weeks starting Monday).
- **Cooldown:** one week after, still no national reallocation, so we can see carryover instead of stuffing spend back in on day 29.

## KPI and success

- **Primary KPI:** **cash sales** (settled dollars). Not ROAS, not platform-reported conversions, not blended MER as the test outcome.
- **Guardrails:** % of treatment weeks with true $0 on the tested channel; no simultaneous sitewide promo that was not in the pre-period pattern; donor markets do not receive the leftover budget.
- **Success (live desk):** the **95% CI on incremental cash sales (ATT) excludes 0**.
- **SAMPLE method check in `01-geolift`:** GeoLift default here is **90%** (`alpha = 0.1`). Do not quote that interval as a 95% test.
- **Failure / freeze:** CI includes 0. We do **not** scale the channel from the OLS point estimate.
- **If the CI excludes 0 but the ATT is far from the OLS contribution:** believe the geo test for *direction*; do not force the MMM coefficient to match a four-week ATT.

## Power honesty

Four weeks is short. Weekly cash is noisy. A 4-week pause in 8 of ~210 DMAs may only detect a large effect. If a proper GeoLift power curve says the MDE is bigger than the OLS-implied lift, we extend the test (or add markets) rather than calling a noisy zero a “disproof.” We still do not scale while that CI includes 0.

## What this test is not

- Not a national holdout.
- Not MTA.
- Not Recast’s ~30k-parameter model.
- Not a GeoLift *result* — there is no ATT in this folder. The ATT in `01-geolift` is a different dataset (package vignette, known +8% inject).

