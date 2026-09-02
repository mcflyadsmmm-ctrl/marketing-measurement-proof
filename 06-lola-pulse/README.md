# SAMPLE: Lola Director pulse (not Lola data)

Synthetic weekly cash MER, a keyword VoC codebook, and a BFCM **planning** interval.
**Not** Lola Blankets orders, tickets, or surveys. **Not** Black Clover. **Not** Nutricost.
This folder did **not** scrape Lola and did **not** run Lola’s VoC.

JD: [Director of Consumer Insights & Marketing Science](https://job-boards.greenhouse.io/lolablankets/jobs/4339422009)
(Lehi or Brooklyn hybrid). Measurement is stronger than customer understanding; this pack
is one narrative across email, SMS, site, organic, and paid. Incrementality is
[`01-geolift`](../01-geolift/) — do not look for a GeoLift rebuild here.

Utah / 8+ years is oral (McFly 2020–present). Not a repo claim.

## The 90-second story (pulse = VoC = BFCM)

1. **Cash MER is the spine.** Net cash / paid spend, weekly, with a SAMPLE break-even line.
2. **Last-click email is distrusted.** Klaviyo-shaped attributed revenue as a share of cash
   **rises** when paid ramps and MER compresses. Do not fund the mix from that series.
   SMS last-click is on the table for the same reason.
3. **VoC names a friction.** Shipping, not creative, is the volume theme. That is the same
   July–August 2025 window where **site CVR** falls on the pulse.
4. **BFCM is a forecast interval, not a promise.** Last year × growth + a promo dummy + a
   residual band. Not a structural MMM.

## Run (Python 3.9.6)

Venv at repo root: `../.venv` (this Mac: `/Users/martysmithson/Documents/Job Search/08 Proof/marketing-measurement-proof/.venv`).

```bash
cd "08 Proof/marketing-measurement-proof/06-lola-pulse"
../.venv/bin/python generate_pulse.py
../.venv/bin/python voc.py
../.venv/bin/python bfcm_forecast.py
../.venv/bin/python plot_pulse.py
```

Expected runtime: under one minute. Seed **2020**.

Writes:

| File | What |
|---|---|
| `out/pulse_table.csv` | Weekly SAMPLE series for Tableau/Looker |
| `out/pulse.png` | Dashboard titled `SAMPLE: weekly cash MER and spend (not Lola data)` |
| `data/cx_tickets.csv` | ~200 synthetic tickets; hidden `theme` is scoring-only |
| `out/voc_themes.csv` | Codebook volumes + one SAMPLE quote per theme |
| `out/BFCM-note.md` | Planning forecast; says it is not an MMM |

## Until Marty logs into Tableau: the PNG is the artifact

Lola’s JD is **Looker or Tableau**, not Looker Studio. Do not screenshot Studio and relabel it.
Until a Tableau Public (or Looker trial) login exists, **`out/pulse.png`** is what a hiring
manager opens. Any later screenshot file name or caption must say **Tableau** or **Looker**.

## Publish `out/pulse_table.csv` to Tableau Public (12 lines)

1. Create a free [Tableau Public](https://public.tableau.com/) account (Marty clicks; Cursor cannot).
2. Install Tableau Desktop Public Edition and sign in.
3. Connect → Text file → this folder’s `out/pulse_table.csv`.
4. Parse `week` as Date. Keep `promo_flag` as number, `annotation` as string.
5. Sheet 1: columns `week`, rows `SUM(paid_spend)` as bars, `AVG(cash_mer)` as a dual-axis line.
6. Title the workbook **SAMPLE: weekly cash MER and spend (not Lola data)**.
7. Sheet 2: `AVG(email_lastclick_share)` with caption “distrusted last-click, not a budget input.”
8. Sheet 3: `AVG(site_cvr)`; annotate the July–August 2025 shipping window from `annotation`.
9. Dashboard those three sheets; color-blind-safe palette; SAMPLE watermark in the title.
10. Save to Tableau Public. Copy the viz URL.
11. Screenshot the **Tableau** workbook (or a Looker explore if you used a Looker trial instead).
12. Filename/caption: `tableau-pulse.png` or `looker-pulse.png` — never `studio`.

## Codebook

[`voc_codebook.md`](voc_codebook.md) — shipping → product → ads → other. Keyword rules only.
`voc.py` reads `ticket_id, date, channel, text` and ignores hidden `theme` except to print
a scoring accuracy (a generator check, not a Lola KPI).

## What this folder will not claim

- Live Lola CX, social, or survey reads
- Black Clover or Nutricost numbers
- A GeoLift or MMM result (wrong folders)
- Looker Studio as a BI proof
