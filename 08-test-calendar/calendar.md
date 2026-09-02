# SAMPLE: 90-day incrementality calendar (Lovevery-style)

Not ads-buyer tips. Not a bidding bot. Not Google/Meta recert. International paid (UK / Canada / Australia / Asia) is **oral** — this calendar is US SAMPLE.

KPI is **cash MER** and **new buyers**, not platform ROAS. Meta geo weeks 1–4 use the same **5% MDE / 4-week** language as `01-geolift` (~80% power on cash sales). Intervention dates are locked in this doc **before** any CausalImpact / GeoLift fit.

Always-on ops kill (hours, not weeks): if hourly cash MER is below break-even for **3 consecutive hours from 11:00**, cut remaining paid that day (`out/intraday_sample.csv` + plot). That readout does not replace the geo/holdout.

Break-even MER for the SAMPLE day = **2.50** (cash / spend). Planning assumption, not a W-2 number.

| Days | Week | Channel / design | Hypothesis | KPI | MDE | Kill criterion |
|---|---|---|---|---|---|---|
| 1–7 | 0 | Lock + instrumentation | Dates, geos, and holdout flags are in the doc before anyone looks at post-period cash. Pixel / cash join is dated. | Cash join rate (orders with a paid click vs net cash in the warehouse) | n/a (gate) | Do not start week 1 if cash cannot be joined same-day within 2 hours of spend. |
| 8–35 | 1–4 | **Meta geo** (4-week test; same MDE language as `01-geolift`) | Meta prospecting is incremental: treated geos lift **cash sales ≥ 5%** vs synthetic controls over T1–T4. | Primary: cash sales. Secondary: new buyers. Guardrail: cash MER. | **5%** relative on cash sales, ~80% power, **4 weeks** | After week 4: if ATT 95% CI includes 0 **and** cannot rule out a 5% miss as underpowered, do not scale. If point ATT is negative and the CI excludes +5%, **cut** Meta prospecting, do not “optimize creative” as the readout. Intra-day: 11:00 MER rule still applies every day of the test. |
| 36–63 | 5–8 | **Google geo or PSA** (4 weeks) | Google paid search is incremental on brand-excluded queries, not last-click claiming existing demand. PSA / ghost-ad or geo holdout recovers ≥ MDE on **new buyers**. | Primary: new buyers. Secondary: cash MER on non-brand. | **5%** relative on new buyers (4 weeks); if PSA variance is higher, pre-declare 6% and do not move it after seeing results | If incremental new buyers CI includes 0, **hold** budget at the test level — do not steal Meta’s week 1–4 learning to “cover” Google. If cash MER on the treated slice is below 2.50 for the full 4 weeks and lift is < MDE, **cut** the non-brand campaign, not the brand exact terms. |
| 64–90 | 9–12 | **TikTok user holdout** (4 weeks; not geo) | TikTok prospecting creates new buyers the cash ledger would not have seen. Holdout is a user flag, not a DMA, because TikTok geo spillover is messy. | Primary: new buyers (4-week window). Secondary: cash MER. | **8%** relative on new buyers (noisier than Meta geo; 8% is the pre-declared MDE, not a hope) | If incremental new buyers 95% CI includes 0 at week 12, **kill** TikTok prospecting. Do not keep it as “upper funnel” without a cash MER path. If MER < 2.50 for 3 hours from 11:00 on any day, cut that day even if the 4-week test is still running. |

## What this calendar will not do

- Will not recertify Google or Meta ads certificates.
- Will not ship a bidding bot.
- Will not treat platform-reported conversions as the KPI.
- Will not geo-test a national brand / product launch — that is `07-causalimpact`, and only with the week locked first.
