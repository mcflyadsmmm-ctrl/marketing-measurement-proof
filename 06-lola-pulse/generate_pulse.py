#!/usr/bin/env python3
"""SAMPLE weekly pulse + synthetic CX tickets. Seed 2020. Not Lola data."""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd

SEED = 2020
N_WEEKS = 104
N_TICKETS = 200
START = pd.Timestamp("2024-01-01")  # Monday

SHIPPING_START = pd.Timestamp("2025-07-07")
SHIPPING_END = pd.Timestamp("2025-08-18")

HERE = Path(__file__).resolve().parent
DATA_DIR = HERE / "data"
OUT_DIR = HERE / "out"

# SAMPLE break-even is a plotting assumption, not a client margin.
BREAK_EVEN_MER = 3.2

ANNOTATIONS = {
    pd.Timestamp("2024-04-08"): (
        "Spring promo: paid up; cash MER compressed"
    ),
    pd.Timestamp("2024-11-25"): (
        "BFCM 2024: promo on; MER at trough"
    ),
    pd.Timestamp("2025-03-10"): (
        "Paid test: spend jumped, cash did not; last-click email share spiked — do not fund from Klaviyo"
    ),
    pd.Timestamp("2025-07-14"): (
        "Site CVR drop; shipping tickets spike (see VoC)"
    ),
    pd.Timestamp("2025-08-11"): (
        "Spend paced so MER held; site CVR still down (shipping VoC)"
    ),
    pd.Timestamp("2025-11-24"): (
        "BFCM 2025: cash up; last-click email over-claims"
    ),
}


def promo_flag_for(week: pd.Timestamp) -> int:
    spring = week in (
        pd.Timestamp("2024-04-08"),
        pd.Timestamp("2024-04-15"),
        pd.Timestamp("2025-04-07"),
        pd.Timestamp("2025-04-14"),
    )
    bfcm = week in (
        pd.Timestamp("2024-11-18"),
        pd.Timestamp("2024-11-25"),
        pd.Timestamp("2024-12-02"),
        pd.Timestamp("2025-11-17"),
        pd.Timestamp("2025-11-24"),
        pd.Timestamp("2025-12-01"),
    )
    return int(spring or bfcm)


def in_shipping_window(ts: pd.Timestamp) -> bool:
    return SHIPPING_START <= ts <= SHIPPING_END


def make_pulse(rng: np.random.Generator) -> pd.DataFrame:
    weeks = pd.date_range(START, periods=N_WEEKS, freq="W-MON")
    t = np.arange(N_WEEKS, dtype=float)
    promo = np.array([promo_flag_for(w) for w in weeks], dtype=float)
    shipping = np.array([in_shipping_window(w) for w in weeks], dtype=float)

    winter = 16000.0 * np.sin(2.0 * np.pi * (t - 4.0) / 52.0)
    cash = (
        188000.0
        + 210.0 * t
        + winter
        + 52000.0 * promo
        - 22000.0 * shipping
        + rng.normal(0.0, 4200.0, N_WEEKS)
    )
    spend = (
        46000.0
        + 35.0 * t
        + 24000.0 * promo
        - 4000.0 * shipping
        + rng.normal(0.0, 1100.0, N_WEEKS)
    )

    # Paid test week: last-click email will claim the bump; cash barely moves.
    paid_test = weeks == pd.Timestamp("2025-03-10")
    spend = np.where(paid_test, spend * 1.38, spend)
    cash = np.where(paid_test, cash * 1.03, cash)

    cash = np.clip(cash, 120000.0, None)
    spend = np.clip(spend, 28000.0, None)
    cash = np.round(cash, 0)
    spend = np.round(spend, 0)
    mer = cash / spend

    email_attr = np.round(0.11 * cash + 0.62 * spend + rng.normal(0.0, 2500.0, N_WEEKS), 0)
    email_attr = np.clip(email_attr, 8000.0, cash * 0.72)
    sms_attr = np.round(0.03 * cash + 0.09 * spend + rng.normal(0.0, 800.0, N_WEEKS), 0)
    sms_attr = np.clip(sms_attr, 1500.0, cash * 0.22)

    sessions = np.round(
        92000.0 + 80.0 * t + 8000.0 * promo - 6000.0 * shipping + rng.normal(0.0, 2200.0, N_WEEKS),
        0,
    )
    sessions = np.clip(sessions, 70000.0, None)
    cvr = (
        0.0212
        + 0.0048 * promo
        - 0.0056 * shipping
        + rng.normal(0.0, 0.00055, N_WEEKS)
    )
    cvr = np.clip(cvr, 0.012, 0.032)
    orders = np.round(sessions * cvr, 0)
    cvr = orders / sessions

    organic = np.round(
        24500.0 + 12.0 * t + 3500.0 * np.sin(2.0 * np.pi * (t - 4.0) / 52.0) + rng.normal(0.0, 700.0, N_WEEKS),
        0,
    )
    organic = np.clip(organic, 18000.0, None)

    notes = [ANNOTATIONS.get(w, "") for w in weeks]
    frame = pd.DataFrame(
        {
            "week": weeks.strftime("%Y-%m-%d"),
            "cash_sales": cash.astype(int),
            "paid_spend": spend.astype(int),
            "cash_mer": np.round(mer, 4),
            "break_even_mer": BREAK_EVEN_MER,
            "email_attributed_revenue": email_attr.astype(int),
            "email_lastclick_share": np.round(email_attr / cash, 4),
            "sms_attributed_revenue": sms_attr.astype(int),
            "site_sessions": sessions.astype(int),
            "site_orders": orders.astype(int),
            "site_cvr": np.round(cvr, 4),
            "organic_sessions": organic.astype(int),
            "promo_flag": promo.astype(int),
            "annotation": notes,
        }
    )
    return frame


SHIPPING_TEXTS = [
    "SAMPLE: Tracking has not moved in six days; package still shows in transit.",
    "SAMPLE: Delivery was four days past the estimated arrival and I missed the event.",
    "SAMPLE: Carrier scan stopped after the warehouse; still waiting on the package.",
    "SAMPLE: Order is in a fulfillment backlog and the ship date slipped twice.",
    "SAMPLE: UPS says delayed; the blanket was supposed to arrive last Friday.",
    "SAMPLE: FedEx delivery exception, box has not shown up, ticket opened again.",
    "SAMPLE: USPS tracking is blank. Is this still in the warehouse?",
    "SAMPLE: Never arrived. Last scan was in transit two weeks ago.",
    "SAMPLE: Late for a housewarming — shipping said 3–5 days, we are on day 11.",
    "SAMPLE: Backorder notice came after purchase; can you expedite fulfillment?",
    "SAMPLE: Package marked delivered but nothing on the porch. Lost?",
    "SAMPLE: Transit time doubled versus checkout. This is the second late order.",
]

PRODUCT_TEXTS = [
    "SAMPLE: Corner stitching opened after two washes.",
    "SAMPLE: Fabric feels thinner than the product page photos.",
    "SAMPLE: Color is much lighter than the site; dye looks faded already.",
    "SAMPLE: Pilling on the edge after one week of use.",
    "SAMPLE: Sizing is off — it is smaller than the dimensions listed.",
    "SAMPLE: Scratchy texture, not the soft hand-feel described.",
    "SAMPLE: Seam on the binding is tearing. Quality issue.",
    "SAMPLE: Sheds lint on the couch; shedding started after the first wash.",
    "SAMPLE: Smell out of the bag has not gone away after airing out.",
    "SAMPLE: Wash instructions followed; fabric still looks worn.",
]

ADS_TEXTS = [
    "SAMPLE: Instagram ad used a promo code that was expired at checkout.",
    "SAMPLE: Facebook advertisement showed a price that was not on the PDP.",
    "SAMPLE: Clicked the ad from TikTok; landing page was a different colorway.",
    "SAMPLE: Retargeting ad kept firing after I already bought.",
    "SAMPLE: Discount code from the Meta ad returned invalid.",
    "SAMPLE: The ad was misleading — hero image is not the SKU in stock.",
    "SAMPLE: TikTok advertisement promised a gift with purchase that did not apply.",
    "SAMPLE: Saw the ad on Instagram, but the bundle was already gone.",
]

OTHER_TEXTS = [
    "SAMPLE: Please add a gift message before this ships.",
    "SAMPLE: Need to change the ship-to address on an unfulfilled order.",
    "SAMPLE: Can you resend the invoice for our records?",
    "SAMPLE: Wholesale inquiry — we run a small shop, not a complaint.",
    "SAMPLE: Password reset on the account is looping; cannot log in.",
    "SAMPLE: Press request for a loft photoshoot, not an order issue.",
    "SAMPLE: Wedding registry question: can guests pick a SKU?",
    "SAMPLE: Want to update the email on the account, nothing wrong with the order.",
]

CHANNELS = ["cx_ticket", "chat", "social", "survey", "sms"]


def _pick(texts: list[str], rng: np.random.Generator) -> str:
    return str(texts[int(rng.integers(0, len(texts)))])


def make_tickets(weeks: pd.DatetimeIndex, rng: np.random.Generator) -> pd.DataFrame:
    """~200 tickets. Hidden theme is for codebook scoring only."""
    n_ship, n_prod, n_ads, n_other = 90, 50, 30, 30
    assert n_ship + n_prod + n_ads + n_other == N_TICKETS

    shock_mondays = [w for w in weeks if in_shipping_window(w)]
    bfcm_mondays = [
        w
        for w in weeks
        if w in (
            pd.Timestamp("2024-11-18"),
            pd.Timestamp("2024-11-25"),
            pd.Timestamp("2024-12-02"),
            pd.Timestamp("2025-11-17"),
            pd.Timestamp("2025-11-24"),
            pd.Timestamp("2025-12-01"),
        )
    ]
    other_mondays = [w for w in weeks if w not in shock_mondays]

    def clustered_dates(n: int, cluster: list, rest: list, cluster_share: float) -> list:
        n_c = int(round(n * cluster_share))
        n_r = n - n_c
        pool_c = cluster if cluster else list(weeks)
        pool_r = rest if rest else list(weeks)
        dates = [pool_c[int(rng.integers(0, len(pool_c)))] for _ in range(n_c)]
        dates.extend(pool_r[int(rng.integers(0, len(pool_r)))] for _ in range(n_r))
        return dates

    ship_dates = clustered_dates(n_ship, shock_mondays, list(weeks), 0.62)
    # A few post-BFCM shipping complaints so the theme is not only July.
    extra_bfcm = min(12, n_ship)
    for i in range(extra_bfcm):
        if bfcm_mondays:
            ship_dates[i] = bfcm_mondays[int(rng.integers(0, len(bfcm_mondays)))]

    prod_dates = clustered_dates(n_prod, other_mondays, list(weeks), 0.85)
    ads_dates = clustered_dates(
        n_ads,
        [
            pd.Timestamp("2024-04-08"),
            pd.Timestamp("2024-04-15"),
            pd.Timestamp("2025-03-10"),
            pd.Timestamp("2025-04-07"),
            pd.Timestamp("2025-04-14"),
            pd.Timestamp("2025-11-17"),
            pd.Timestamp("2025-11-24"),
        ],
        list(weeks),
        0.55,
    )
    other_dates = clustered_dates(n_other, other_mondays, list(weeks), 0.9)

    rows = []
    ticket_id = 1

    def add(theme: str, dates: list, texts: list[str]) -> None:
        nonlocal ticket_id
        for d in dates:
            day = d + pd.Timedelta(days=int(rng.integers(0, 7)))
            rows.append(
                {
                    "ticket_id": f"T{ticket_id:04d}",
                    "date": day.strftime("%Y-%m-%d"),
                    "channel": CHANNELS[int(rng.integers(0, len(CHANNELS)))],
                    "text": _pick(texts, rng),
                    "theme": theme,
                }
            )
            ticket_id += 1

    add("shipping", ship_dates, SHIPPING_TEXTS)
    add("product", prod_dates, PRODUCT_TEXTS)
    add("ads", ads_dates, ADS_TEXTS)
    add("other", other_dates, OTHER_TEXTS)

    frame = pd.DataFrame(rows)
    frame = frame.sample(frac=1.0, random_state=SEED).reset_index(drop=True)
    return frame


def main() -> None:
    rng = np.random.default_rng(SEED)
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    pulse = make_pulse(rng)
    weeks = pd.to_datetime(pulse["week"])
    tickets = make_tickets(pd.DatetimeIndex(weeks), rng)

    pulse_path = OUT_DIR / "pulse_table.csv"
    tickets_path = DATA_DIR / "cx_tickets.csv"
    pulse.to_csv(pulse_path, index=False)
    tickets.to_csv(tickets_path, index=False)

    mer = pulse["cash_mer"]
    share = pulse["email_lastclick_share"]
    shock = pulse[weeks.between(SHIPPING_START, SHIPPING_END)]
    print(f"wrote {pulse_path} ({len(pulse)} weeks, seed {SEED})")
    print(f"wrote {tickets_path} ({len(tickets)} tickets; hidden theme is scoring-only)")
    print(
        f"cash MER median {mer.median():.2f}; "
        f"email last-click share median {share.median():.1%} "
        f"(rises when MER falls — last-click is distrusted)"
    )
    print(
        f"shipping window site CVR {shock['site_cvr'].mean():.2%} vs "
        f"all-weeks {pulse['site_cvr'].mean():.2%}"
    )


if __name__ == "__main__":
    main()
