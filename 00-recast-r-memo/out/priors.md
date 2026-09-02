# SAMPLE: channel priors (operator experience, not this dataset)

These are **PRIORS** — beliefs a media operator would write down *before* looking at the OLS fit in `tidy.csv`. They are not posteriors, not last-click ROAS, and not the data-generating process in the README.

Recast onboarding asks you to set priors with the client, then interpret the model, then plan a test. This file is that first step.

## Google (Search + Shopping mix)

- **PRIOR (return):** cash per adstocked dollar somewhere in **$1.20–$2.40**. Branded query is partly stolen from demand that would have arrived anyway; non-brand and Shopping are closer to capture.
- **PRIOR (carryover):** moderate. Most of the click-to-cash happens inside a week; a leftover halo of about half a week is plausible (geometric θ near 0.4–0.6).
- **PRIOR (saturation):** already a large share of paid. Extra dollars likely diminish faster than Meta prospecting.
- **Source:** operator experience on paid search. **Not this SAMPLE regression.**

## Meta

- **PRIOR (return):** cash per adstocked dollar **$1.60–$2.80** if creative is working. Last-click under-credits prospecting and over-credits retargeting; the net in cash is usually better than the ads manager in an iOS-attribution world.
- **PRIOR (carryover):** longer than Google. View-through and delayed branded search show up in later weeks (θ prior 0.45–0.65).
- **PRIOR (saturation):** still room if frequency is not already high; do not scale retargeting pools as if they were net-new.
- **Source:** operator experience. **Not this SAMPLE regression.**

## TikTok

- **PRIOR (return):** weak same-week cash. **$0.15–$0.90** per adstocked dollar is the honest range. Upper-funnel education, not a demand-capture channel.
- **PRIOR (carryover):** medium (θ prior 0.35–0.55) but the *level* of cash is the uncertainty, not the decay.
- **PRIOR (saturation):** unknown until the channel is out of “learning.” High uncertainty is the prior.
- **Source:** operator experience. **Not this SAMPLE regression.** This is the channel I would geo-test first if the model interval is wide.

## Amazon Ads

- **PRIOR (return):** closer to intent capture than TikTok. **$0.60–$1.40** per adstocked dollar. Competes with organic marketplace rank; some spend is defensive.
- **PRIOR (carryover):** shorter than Meta (θ prior 0.30–0.50).
- **PRIOR (saturation):** share-of-voice on the SKU matters more than a national reach curve.
- **Source:** operator experience. **Not this SAMPLE regression.**

## Promo weeks

- **PRIOR:** sitewide sale / BFCM-ish weeks move cash a lot. Always include the flag so paid channels do not steal promo.
- **Source:** operator experience. **Not this SAMPLE regression.**

## What these priors are for

If the OLS interval lands inside the prior, we still do not scale the weakest channel from the regression alone. If it lands outside, we do not “update” by staring at last-click. We write the disagreement down and test cash in geos.

