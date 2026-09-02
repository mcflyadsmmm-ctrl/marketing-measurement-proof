#!/usr/bin/env python3
"""SAMPLE BFCM planning forecast: last year × growth + promo dummy + residual interval.

Not a structural MMM. Incrementality lives in 01-geolift.
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd
import statsmodels.api as sm

HERE = Path(__file__).resolve().parent
PULSE = HERE / "out" / "pulse_table.csv"
NOTE = HERE / "out" / "BFCM-note.md"

BFCM_2025 = (
    pd.Timestamp("2025-11-17"),
    pd.Timestamp("2025-11-24"),
    pd.Timestamp("2025-12-01"),
)


def _money(n: float) -> str:
    return f"${n:,.0f}"


def main() -> None:
    if not PULSE.exists():
        raise SystemExit(f"missing {PULSE}; run generate_pulse.py first")

    df = pd.read_csv(PULSE, parse_dates=["week"])
    df = df.sort_values("week").reset_index(drop=True)
    df["t"] = np.arange(len(df), dtype=float)
    df["woy"] = df["week"].dt.isocalendar().week.astype(int)
    df["year"] = df["week"].dt.year.astype(int)

    nonpromo = df[df["promo_flag"] == 0]
    y24 = nonpromo[nonpromo["year"] == 2024][["woy", "cash_sales", "paid_spend"]]
    y25 = nonpromo[nonpromo["year"] == 2025][["woy", "cash_sales", "paid_spend"]]
    paired = y24.merge(y25, on="woy", suffixes=("_24", "_25"))
    if paired.empty:
        raise SystemExit("no paired non-promo weeks to estimate growth")
    g_cash = float((paired["cash_sales_25"] / paired["cash_sales_24"]).median() - 1.0)
    g_spend = float((paired["paid_spend_25"] / paired["paid_spend_24"]).median() - 1.0)

    x = sm.add_constant(df[["t", "promo_flag"]], has_constant="add")
    ols = sm.OLS(df["cash_sales"].astype(float), x).fit()
    beta_promo = float(ols.params["promo_flag"])
    resid_sd = float(np.std(ols.resid, ddof=1))
    z = 1.96
    half = z * resid_sd

    rows = []
    for week_ly in BFCM_2025:
        ly = df.loc[df["week"] == week_ly]
        if ly.empty:
            raise SystemExit(f"missing last-year week {week_ly.date()}")
        cash_ly = float(ly["cash_sales"].iloc[0])
        spend_ly = float(ly["paid_spend"].iloc[0])
        mer_ly = float(ly["cash_mer"].iloc[0])
        email_share_ly = float(ly["email_lastclick_share"].iloc[0])
        week_fc = week_ly + pd.Timedelta(weeks=52)
        # Last year de-promo'd, grown, then promo dummy added once (no double count).
        grown_runrate = (cash_ly - beta_promo) * (1.0 + g_cash)
        point = grown_runrate + beta_promo
        spend_plan = spend_ly * (1.0 + g_spend)
        mer_point = point / spend_plan
        rows.append(
            {
                "week": week_fc.strftime("%Y-%m-%d"),
                "last_year_week": week_ly.strftime("%Y-%m-%d"),
                "cash_ly": cash_ly,
                "spend_ly": spend_ly,
                "mer_ly": mer_ly,
                "email_share_ly": email_share_ly,
                "point": point,
                "lo": point - half,
                "hi": point + half,
                "spend_plan": spend_plan,
                "mer_point": mer_point,
                "mer_lo": (point - half) / spend_plan,
                "mer_hi": (point + half) / spend_plan,
            }
        )

    fc = pd.DataFrame(rows)
    cash_sum = float(fc["point"].sum())
    cash_lo = float(fc["lo"].sum())
    cash_hi = float(fc["hi"].sum())
    spend_sum = float(fc["spend_plan"].sum())
    mer_event = cash_sum / spend_sum
    rsq = float(ols.rsquared)
    email_share_bfcm = float(df[df["week"].isin(BFCM_2025)]["email_lastclick_share"].mean())
    email_share_else = float(df[~df["week"].isin(BFCM_2025)]["email_lastclick_share"].mean())
    mer_bfcm = float(df[df["week"].isin(BFCM_2025)]["cash_mer"].mean())
    mer_else = float(df[df["promo_flag"] == 0]["cash_mer"].mean())
    be = float(df["break_even_mer"].iloc[0])

    week_lines = []
    for r in rows:
        week_lines.append(
            "- **{week}**: point {pt} (interval {lo}–{hi}); "
            "planned spend {sp}; cash MER {mer:.2f} (band {mlo:.2f}–{mhi:.2f}). "
            "Last year {ly} was {cly} cash at MER {mly:.2f}.".format(
                week=r["week"],
                pt=_money(r["point"]),
                lo=_money(r["lo"]),
                hi=_money(r["hi"]),
                sp=_money(r["spend_plan"]),
                mer=r["mer_point"],
                mlo=r["mer_lo"],
                mhi=r["mer_hi"],
                ly=r["last_year_week"],
                cly=_money(r["cash_ly"]),
                mly=r["mer_ly"],
            )
        )

    note = f"""# SAMPLE: BFCM 2026 planning note (not Lola data)

This is a **planning forecast**, not a structural MMM. No adstock, no saturation,
no geo test. Incrementality is `01-geolift`, not this file. Email last-click is
**not an input**. Tickets are synthetic; this note does not claim a Lola VoC run.

## Decision (same story as the pulse and VoC)

Pace **cash MER**, not Klaviyo. Last year’s BFCM weeks already show MER
compressing to **{mer_bfcm:.2f}** versus **{mer_else:.2f}** on non-promo weeks,
while email last-click share **rises** ({email_share_bfcm:.1%} vs
{email_share_else:.1%} off-event). That share is distrusted: last-click steals
paid. The VoC codebook names **shipping** as the friction that moved site CVR
in July–August 2025 — the downside inside this band is a fulfillment miss, not
“email broke.”

Three-week SAMPLE point: **{_money(cash_sum)}** cash on **{_money(spend_sum)}**
planned spend (event MER **{mer_event:.2f}**). Residual interval
**{_money(cash_lo)}–{_money(cash_hi)}**. That interval is a planning band, not
a promise.

## Method

1. **Growth (g)** from paired non-promo week-of-year 2024 vs 2025: cash
   **{g_cash:.1%}**, spend **{g_spend:.1%}**.
2. **Promo dummy** from OLS `cash_sales ~ t + promo_flag` on the SAMPLE weekly
   series (R² {rsq:.2f}): **{_money(beta_promo)}** per promo week.
3. **Point** for each 2026 week = (last year’s cash − dummy) × (1+g) + dummy.
   Last year already contains the event; we do not add the dummy twice.
4. **Interval** = point ± 1.96 × residual SD (**{_money(resid_sd)}**). This is
   a residual band, not a full prediction interval with parameter uncertainty.

SAMPLE break-even MER on the pulse table is **{be:.1f}** (an assumption, not a
client margin). If in-week cash MER sits below that for three consecutive cuts,
pace spend down — same rule as the weekly pulse.

## 2026 weeks (52 weeks after 2025 BFCM)

{chr(10).join(week_lines)}

## What this will not do

- Will not treat last-click email or SMS attributed revenue as demand.
- Will not ship a Robyn/Meridian budget call from this dummy.
- Will not ignore shipping VoC: if transit tickets spike like July 2025, the
  **low** end of the band is the operating case, not the point.

*SAMPLE synthetic series. Seed 2020. Not Black Clover. Not Nutricost.*
"""
    NOTE.parent.mkdir(parents=True, exist_ok=True)
    NOTE.write_text(note, encoding="utf-8")
    print(f"wrote {NOTE}")
    print(
        f"g_cash={g_cash:.1%} promo_dummy={beta_promo:,.0f} "
        f"resid_sd={resid_sd:,.0f} event_point={cash_sum:,.0f} "
        f"interval={cash_lo:,.0f}–{cash_hi:,.0f}"
    )


if __name__ == "__main__":
    main()
