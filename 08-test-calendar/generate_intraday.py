#!/usr/bin/env python3
"""SAMPLE one-day hourly spend vs cash-proxy.

MER is below break-even from 11:00 for 3 hours (11, 12, 13).
Not a bidding bot. Not ads-buyer tips.
"""
from __future__ import annotations

import sys
from pathlib import Path

import pandas as pd

HERE = Path(__file__).resolve().parent
OUT = HERE / "out"
OUT.mkdir(parents=True, exist_ok=True)

BREAK_EVEN_MER = 2.50
SAMPLE_DATE = "2026-08-11"

# Hourly SAMPLE cash / spend. Hours 11–13 are the kill window.
# Other hours stay at or above break-even on purpose.
ROWS = [
    # hour, spend, cash_proxy
    (0, 90.0, 360.0),
    (1, 70.0, 280.0),
    (2, 55.0, 220.0),
    (3, 50.0, 205.0),
    (4, 60.0, 240.0),
    (5, 80.0, 320.0),
    (6, 140.0, 490.0),
    (7, 220.0, 770.0),
    (8, 380.0, 1330.0),
    (9, 520.0, 1820.0),
    (10, 680.0, 2380.0),
    (11, 2200.0, 3520.0),  # MER 1.60
    (12, 2400.0, 3600.0),  # MER 1.50
    (13, 2100.0, 3990.0),  # MER 1.90
    (14, 900.0, 3150.0),
    (15, 820.0, 2870.0),
    (16, 760.0, 2660.0),
    (17, 700.0, 2450.0),
    (18, 640.0, 2240.0),
    (19, 500.0, 1750.0),
    (20, 360.0, 1260.0),
    (21, 240.0, 840.0),
    (22, 160.0, 560.0),
    (23, 110.0, 385.0),
]


def main() -> int:
    hours = []
    spend = []
    cash = []
    for h, s, c in ROWS:
        hours.append(h)
        spend.append(s)
        cash.append(c)
    mer = [c / s for s, c in zip(spend, cash)]
    below = [m < BREAK_EVEN_MER for m in mer]
    df = pd.DataFrame(
        {
            "sample_date": SAMPLE_DATE,
            "hour": hours,
            "hour_label": [f"{h:02d}:00" for h in hours],
            "spend_usd": spend,
            "cash_proxy_usd": cash,
            "mer": [round(m, 4) for m in mer],
            "break_even_mer": BREAK_EVEN_MER,
            "below_break_even": below,
        }
    )
    kill = df.loc[df["below_break_even"], "hour_label"].tolist()
    if kill != ["11:00", "12:00", "13:00"]:
        raise SystemExit(f"Expected kill hours 11:00–13:00, got {kill}")
    path = OUT / "intraday_sample.csv"
    df.to_csv(path, index=False)
    print(
        f"SAMPLE {SAMPLE_DATE}: break-even MER {BREAK_EVEN_MER:.2f}; "
        f"below from {kill[0]} for {len(kill)} hours → cut."
    )
    print(f"Wrote {path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
