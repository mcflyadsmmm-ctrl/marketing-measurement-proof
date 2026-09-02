# SAMPLE: national CausalImpact (what besides geo?)

CausalImpact asks: after a date we locked *before* seeing post-period results, did national cash beat the counterfactual built from pre-period only?

You need a clean pre-period, covariates the campaign did not treat (SAMPLE search index + category demand), and no other national shock on the same week.

GeoLift identifies with untreated markets. This identifies a national launch or pause when you cannot hold out geos (brand, product, Firefox feature).

The estimand is the gap vs the predicted series, pointwise and cumulative, with a 95% interval — not platform ROAS.

If you move the intervention date after looking, a “lift” can appear anyway. That design does not ship (`out/failure_moved_date.md`).

Saturation (Hill) is an MMM curve assumption. It is not this time-series intervention.

Python here is a transparent pre-period regression. It is **not** Brodersen. Named library: R `CausalImpact` once R exists (`R/run_causalimpact.R`).

```bash
# from this folder; Python 3.9.6; repo .venv
../.venv/bin/python python/failure_case.py
../.venv/bin/python python/saturation_hill.py
# when R exists: Rscript R/run_causalimpact.R
```
