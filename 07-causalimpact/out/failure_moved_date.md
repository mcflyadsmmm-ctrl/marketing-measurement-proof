# SAMPLE: failure case — intervention date moved after the fact

SAMPLE. This Python is not Brodersen; R CausalImpact is the named library once R exists.

**Would not ship this design.** The true shock is week 80. Declaring week 60 as the start (20 weeks early) still produces a positive “lift” because the real +12% sits inside the mis-dated post window. That is not identification. It is a date you chose after the series existed.

| Lock | Value |
|---|---|
| Pre-period (wrong) | weeks 1–59 |
| Post-period (wrong) | weeks 60–104 |
| True DGP intervention | week 80 |
| True DGP lift | 12.0% from week 80, **zero** in weeks 60–79 |

## Spurious readout (same series, wrong date)

- Average relative “lift” over weeks 60–104: **6.7%** (95% CI 5.1% to 8.3%).
- Average weekly gap: **$3,842** (95% CI $2,966 to $4,698).
- Cumulative gap from the fake start: **$172,898** (95% CI $133,467 to $211,409).
- CI excludes zero (looks “significant”): **yes**.

## Why it is a lie

- Weeks 60–79 (no DGP shock): average relative gap **1.0%** — this slice is the honest test of a week-60 start, and it is not a +12% launch.
- Weeks 80–104 still carry the real shock, so the *average* over the long fake post period is pulled positive (~ 12.0% × share of post weeks that are actually treated).

A Firefox marketer version: if you pick the date after you see the line go up, CausalImpact will happily draw a gap. Lock the week in the test doc before anyone fits. If the date was not locked, do not ship the number.

