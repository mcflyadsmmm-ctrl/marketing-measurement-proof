# SAMPLE: national CausalImpact (what besides geo?)

CausalImpact asks: after a date we locked *before* seeing post-period results, did national cash beat the counterfactual built from pre-period only?

You need a clean pre-period, covariates the campaign did not treat (SAMPLE search index + category demand), and no other national shock on the same week.

GeoLift identifies with untreated markets. This identifies a national launch or pause when you cannot hold out geos (brand, product, Firefox feature).

The estimand is the gap vs the predicted series, pointwise and cumulative, with a 95% interval — not platform ROAS.

If you move the intervention date after looking, a “lift” can appear anyway. That design does not ship (`out/failure_moved_date.md`).

Saturation (Hill) is an MMM curve assumption. It is not this time-series intervention.

Python here is a transparent pre-period regression. It is **not** Brodersen. Named library: R `CausalImpact` **has run** (`R/run_causalimpact.R`): good design recovers **~11.2%** vs known +12%, p≈0.001; moved date still fakes lift.

Saturation Hill from Robyn: `02-robyn/out/SAMPLE_robyn_saturation_facebook_I.png`. Saturation is an MMM assumption; CausalImpact is a time-series intervention.

```bash
# from this folder
../.venv/bin/python python/failure_case.py
../.venv/bin/python python/saturation_hill.py
Rscript R/run_causalimpact.R
```
