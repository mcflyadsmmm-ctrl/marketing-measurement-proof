# SAMPLE: CMO memo — cash vs claimed conversions

This is **SAMPLE** synthetic data. Not a client. The model is OLS plus geometric adstock — not a ~30k-parameter Bayesian MMM.

## Why finance should ignore the ads managers

Platform-reported conversions and cash sales do not match. Correlation is **0.86**. Claimed conversions run **1.41×** implied orders (cash / $68 AOV). Google and Meta both claim overlapping purchases. Missing before impute: TikTok spend 1.9%, platform conversions 1.0%. We modeled **cash sales**.

## What we fit

Train weeks 1–91, holdout 92–104. Shared geometric adstock θ = **0.5** by holdout RMSE on cash (**$5,383**; grid 0.3 / 0.5 / 0.7). Train R² = 0.941. Promo week adds $13,686 cash (95% CI $9,501 to $17,871). That is a dummy, not a media ROI. Paid channels do not get credit for BFCM-ish weeks. Baseline (intercept) is $78,843 per week.

Spend mix on train: Google 37.3%, Meta 29.4%, TikTok 15.4%, Amazon 17.9%.

Cash per **adstocked** dollar (not last-click ROAS):

- Google: $1.43 per adstocked dollar (95% CI $1.11 to $1.75)
- Meta: $2.07 per adstocked dollar (95% CI $1.66 to $2.47)
- TikTok: $0.32 per adstocked dollar (95% CI $0.17 to $0.47)
- Amazon: $0.87 per adstocked dollar (95% CI $0.11 to $1.63)

Max paid-channel VIF is 3.17 — collinearity is not the main story.
VIF: Google VIF 3.04; Meta VIF 2.08; TikTok VIF 1.34; Amazon VIF 3.17.

## Cut / hold / scale

**Scale — Meta.** 95% CI is entirely above 0 ($1.66 to $2.47). Point estimate $2.07 cash per adstocked dollar. Add dollars in steps; do not dump the freeze-channel budget into it.

**Hold — Google, TikTok.** Keep near the training mix (Google 37.3% / Meta 29.4% / TikTok 15.4% / Amazon 17.9%) until the Amazon geo test is back.

**Do not scale — Amazon.** Widest interval ($1.51; $0.11 to $1.63). Point estimate $0.87 is not a license to scale. Geo design in experiment.md: KPI = cash sales; success = 95% CI on incremental cash excludes 0.

## What we will not do until the geo test

We will not reallocate the Amazon annual plan from this OLS interval.
We will not treat platform-reported conversions as the geo KPI.
We will not add channel interaction terms and call that incrementality.
We will not change national creative or dump leftover budget into donor markets during the four-week window.
We will not quote last-click ROAS as the decision.

## Next

1. Keep `priors.md` as beliefs, separate from this fit.
2. Run the geo test on **Amazon** (design in experiment.md).
3. Change scale / hold / cut only after the cash ATT interval, not after another dashboard export.

