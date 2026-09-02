# SAMPLE: good design — intervention week locked before fit

SAMPLE. This Python is not Brodersen; R CausalImpact is the named library once R exists.

Pre-period and post-period were declared **before** fitting. They were not chosen from the post-period plot.

| Lock | Value |
|---|---|
| Pre-period (declared) | weeks 1–79 |
| Post-period (declared) | weeks 80–104 |
| True DGP intervention | week 80 |
| True DGP lift | 12.0% multiplicative on cash |
| Post weeks | 25 |

## Recovered effect (pre-period OLS on untreated covariates)

- Average relative lift: **11.2%** (95% CI 9.9% to 12.6%).
- Average weekly gap: **$6,448** (95% CI $5,756 to $7,158).
- Cumulative post gap: **$161,200** (95% CI $143,904 to $178,944).
- Interval contains the known +12%: **yes**.
- Interval excludes zero: **yes**.

OLS R² on the pre-period: 0.061. Covariates: SAMPLE search index, SAMPLE category demand (not treated). 95% CI is a residual bootstrap of the pre-period OLS — not a Brodersen posterior. A live Firefox series would be noisier still; do not quote this interval as a W-2 result.

This is the design you can defend: date locked, covariates untreated, honest CI. GeoLift is still the tool when you can hold out markets. This is the national-series alternative Mozilla asks about.

