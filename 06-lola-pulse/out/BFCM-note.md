# SAMPLE: BFCM 2026 planning note (not Lola data)

This is a **planning forecast**, not a structural MMM. No adstock, no saturation,
no geo test. Incrementality is `01-geolift`, not this file. Email last-click is
**not an input**. Tickets are synthetic; this note does not claim a Lola VoC run.

## Decision (same story as the pulse and VoC)

Pace **cash MER**, not Klaviyo. Last year’s BFCM weeks already show MER
compressing to **3.35** versus **4.15** on non-promo weeks,
while email last-click share **rises** (30.0% vs
26.1% off-event). That share is distrusted: last-click steals
paid. The VoC codebook names **shipping** as the friction that moved site CVR
in July–August 2025 — the downside inside this band is a fulfillment miss, not
“email broke.”

Three-week SAMPLE point: **$778,615** cash on **$227,646**
planned spend (event MER **3.42**). Residual interval
**$704,200–$853,030**. That interval is a planning band, not
a promise.

## Method

1. **Growth (g)** from paired non-promo week-of-year 2024 vs 2025: cash
   **5.5%**, spend **2.2%**.
2. **Promo dummy** from OLS `cash_sales ~ t + promo_flag` on the SAMPLE weekly
   series (R² 0.62): **$53,776** per promo week.
3. **Point** for each 2026 week = (last year’s cash − dummy) × (1+g) + dummy.
   Last year already contains the event; we do not add the dummy twice.
4. **Interval** = point ± 1.96 × residual SD (**$12,656**). This is
   a residual band, not a full prediction interval with parameter uncertainty.

SAMPLE break-even MER on the pulse table is **3.2** (an assumption, not a
client margin). If in-week cash MER sits below that for three consecutive cuts,
pace spend down — same rule as the weekly pulse.

## 2026 weeks (52 weeks after 2025 BFCM)

- **2026-11-16**: point $255,051 (interval $230,246–$279,856); planned spend $75,896; cash MER 3.36 (band 3.03–3.69). Last year 2025-11-17 was $244,519 cash at MER 3.29.
- **2026-11-23**: point $265,748 (interval $240,943–$290,553); planned spend $75,154; cash MER 3.54 (band 3.21–3.87). Last year 2025-11-24 was $254,656 cash at MER 3.46.
- **2026-11-30**: point $257,816 (interval $233,011–$282,621); planned spend $76,595; cash MER 3.37 (band 3.04–3.69). Last year 2025-12-01 was $247,139 cash at MER 3.30.

## What this will not do

- Will not treat last-click email or SMS attributed revenue as demand.
- Will not ship a Robyn/Meridian budget call from this dummy.
- Will not ignore shipping VoC: if transit tickets spike like July 2025, the
  **low** end of the band is the operating case, not the point.

*SAMPLE synthetic series. Seed 2020. Not Black Clover. Not Nutricost.*
