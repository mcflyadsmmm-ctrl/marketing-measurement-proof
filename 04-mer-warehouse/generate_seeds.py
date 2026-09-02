#!/usr/bin/env python3
"""SAMPLE seed generator for the cash MER warehouse. Fixed RNG seed 2020. Not client data."""
from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd

SEED = 2020
N_DAYS = 90
START = "2024-01-01"
CHANNELS = ["Google", "Meta", "TikTok", "Microsoft"]
LAST_CLICK = CHANNELS + ["Email", "Direct"]
# Last-click is a partition of orders. Platform pixels are not.
LAST_CLICK_P = np.array([0.27, 0.31, 0.09, 0.05, 0.14, 0.14])
# Share of *all* orders each paid pixel claims (overlap is the lesson).
CLAIM_P = {"Google": 0.50, "Meta": 0.46, "TikTok": 0.20, "Microsoft": 0.11}
VIEW_THROUGH_P = {"Google": 0.08, "Meta": 0.12, "TikTok": 0.06, "Microsoft": 0.03}
BASE_SPEND = {"Google": 4200.0, "Meta": 5100.0, "TikTok": 1800.0, "Microsoft": 900.0}
AOV = 68.0

OUT = Path(__file__).resolve().parent / "seeds"


def main() -> None:
    rng = np.random.default_rng(SEED)
    dates = pd.date_range(START, periods=N_DAYS, freq="D")
    OUT.mkdir(parents=True, exist_ok=True)

    spend_rows = []
    order_rows = []
    session_rows = []
    email_rows = []
    order_seq = 1

    for day in dates:
        weekend = day.dayofweek >= 5
        spend_mult = 0.72 if weekend else 1.0
        spend_mult *= float(rng.uniform(0.88, 1.12))
        day_spend = {}
        for channel in CHANNELS:
            noise = float(rng.uniform(0.90, 1.10))
            spend = round(BASE_SPEND[channel] * spend_mult * noise, 2)
            day_spend[channel] = spend

        total_spend = sum(day_spend.values())
        lam = 42.0 + 0.12 * np.sqrt(total_spend) + (6.0 if weekend else 0.0)
        n_orders = int(rng.poisson(lam))
        n_orders = max(n_orders, 12)

        gross = np.round(np.clip(rng.normal(AOV, 18.0, n_orders), 12.0, 280.0), 2)
        is_return = rng.random(n_orders) < 0.10
        ret_frac = np.where(is_return, rng.uniform(0.20, 1.00, n_orders), 0.0)
        returns = np.round(gross * ret_frac, 2)
        net_cash = np.round(gross - returns, 2)
        last_click = rng.choice(LAST_CLICK, size=n_orders, p=LAST_CLICK_P)

        for i in range(n_orders):
            order_rows.append(
                {
                    "order_id": "ORD-{0:06d}".format(order_seq),
                    "order_date": day.strftime("%Y-%m-%d"),
                    "gross": float(gross[i]),
                    "returns": float(returns[i]),
                    "net_cash": float(net_cash[i]),
                    "last_click_channel": str(last_click[i]),
                }
            )
            order_seq += 1

        for channel in CHANNELS:
            claimed = int(rng.binomial(n_orders, CLAIM_P[channel]))
            claimed += int(rng.poisson(n_orders * VIEW_THROUGH_P[channel]))
            spend_rows.append(
                {
                    "date": day.strftime("%Y-%m-%d"),
                    "channel": channel,
                    "spend": day_spend[channel],
                    "platform_reported_conversions": claimed,
                }
            )

        converting_sessions = n_orders + int(rng.integers(0, 10))
        cvr = float(rng.uniform(0.022, 0.038))
        sessions = int(np.ceil(converting_sessions / cvr))
        session_rows.append(
            {
                "date": day.strftime("%Y-%m-%d"),
                "sessions": sessions,
                "converting_sessions": converting_sessions,
            }
        )

        email_last_click_cash = float(
            net_cash[np.array(last_click) == "Email"].sum()
        )
        send_mult = 0.55 if weekend else 1.0
        sends = int(rng.normal(24000 * send_mult, 1800 * send_mult))
        sends = max(sends, 4000)
        ctr = float(rng.uniform(0.018, 0.028))
        clicks = min(sends, int(rng.binomial(sends, ctr)))
        # Last-click email cash plus stolen paid credit — distrust this number.
        attributed = round(
            email_last_click_cash * 1.45 + 0.06 * float(net_cash.sum()) + float(rng.normal(0, 40)),
            2,
        )
        attributed = max(attributed, 0.0)
        email_rows.append(
            {
                "date": day.strftime("%Y-%m-%d"),
                "sends": sends,
                "clicks": clicks,
                "attributed_revenue": attributed,
            }
        )

    ads = pd.DataFrame(spend_rows)
    orders = pd.DataFrame(order_rows)
    sessions = pd.DataFrame(session_rows)
    email = pd.DataFrame(email_rows)

    if (orders["net_cash"] > orders["gross"]).any():
        raise AssertionError("SAMPLE generator produced net_cash > gross")
    if (sessions["converting_sessions"] > sessions["sessions"]).any():
        raise AssertionError("SAMPLE generator produced converting_sessions > sessions")
    if (email["clicks"] > email["sends"]).any():
        raise AssertionError("SAMPLE generator produced clicks > sends")

    ads.to_csv(OUT / "ads_spend_daily.csv", index=False)
    orders.to_csv(OUT / "orders.csv", index=False)
    sessions.to_csv(OUT / "sessions.csv", index=False)
    email.to_csv(OUT / "email_sends.csv", index=False)

    claimed_conv = int(ads["platform_reported_conversions"].sum())
    cash = float(orders["net_cash"].sum())
    claimed_rev = claimed_conv * AOV
    print(
        "SAMPLE seeds written to {0} ({1} order rows, {2} spend rows). "
        "claimed conversions {3} x AOV {4:.0f} = {5:.0f} vs net_cash {6:.0f} ({7:.2f}x).".format(
            OUT,
            len(orders),
            len(ads),
            claimed_conv,
            AOV,
            claimed_rev,
            cash,
            claimed_rev / cash,
        )
    )


if __name__ == "__main__":
    main()
