#!/usr/bin/env python3
"""Apply the SAMPLE VoC codebook. Does not read hidden theme except to score."""

from __future__ import annotations

import re
from pathlib import Path

import pandas as pd

HERE = Path(__file__).resolve().parent
TICKETS = HERE / "data" / "cx_tickets.csv"
OUT = HERE / "out" / "voc_themes.csv"

# Word-bounded unless the pattern already includes spaces / boundaries.
SHIPPING = [
    r"delay",
    r"delayed",
    r"late",
    r"tracking",
    r"tracker",
    r"carrier",
    r"transit",
    r"delivery",
    r"delivered",
    r"package",
    r"parcel",
    r"shipping",
    r"warehouse",
    r"backorder",
    r"backlog",
    r"fulfillment",
    r"usps",
    r"ups",
    r"fedex",
    r"lost",
    r"never arrived",
    r"in transit",
    r"estimated arrival",
]
PRODUCT = [
    r"quality",
    r"tear",
    r"torn",
    r"pilling",
    r"pill",
    r"sizing",
    r"color",
    r"texture",
    r"wash",
    r"washed",
    r"washing",
    r"smell",
    r"odor",
    r"stitch",
    r"stitching",
    r"seam",
    r"fabric",
    r"scratchy",
    r"shedding",
    r"dye",
    r"faded",
    r"thin",
    r"thinner",
]
ADS = [
    r"advertisement",
    r"facebook",
    r"instagram",
    r"tiktok",
    r"retarget",
    r"retargeting",
    r"promo code",
    r"discount code",
    r"misleading",
    r"\bad\b",
    r"\bads\b",
    r"clicked the ad",
]

THEME_ORDER = ("shipping", "product", "ads")
PATTERNS = {
    "shipping": SHIPPING,
    "product": PRODUCT,
    "ads": ADS,
}


def _compile(token: str) -> re.Pattern:
    if token.startswith(r"\b") or " " in token:
        return re.compile(token, re.IGNORECASE)
    return re.compile(r"\b" + token + r"\b", re.IGNORECASE)


COMPILED = {
    theme: [_compile(tok) for tok in tokens] for theme, tokens in PATTERNS.items()
}


def classify(text: str) -> str:
    blob = "" if text is None else str(text)
    for theme in THEME_ORDER:
        for pat in COMPILED[theme]:
            if pat.search(blob):
                return theme
    return "other"


def pick_example(tagged: pd.DataFrame, theme: str) -> str:
    sub = tagged[tagged["voc_theme"] == theme]
    if sub.empty:
        return ""
    if theme == "shipping":
        dates = pd.to_datetime(sub["date"])
        shock = sub[(dates >= "2025-07-07") & (dates <= "2025-08-18")]
        pool = shock if len(shock) else sub
    else:
        pool = sub
    pool = pool.sort_values("date")
    quote = str(pool.iloc[len(pool) // 2]["text"])
    if not quote.startswith("SAMPLE"):
        quote = "SAMPLE: " + quote
    return quote


def main() -> None:
    if not TICKETS.exists():
        raise SystemExit(f"missing {TICKETS}; run generate_pulse.py first")

    # Hidden theme is not a model feature.
    visible = pd.read_csv(TICKETS, usecols=["ticket_id", "date", "channel", "text"])
    visible["voc_theme"] = visible["text"].map(classify)

    rows = []
    for theme in ("shipping", "product", "ads", "other"):
        sub = visible[visible["voc_theme"] == theme]
        rows.append(
            {
                "theme": theme,
                "volume": int(len(sub)),
                "example_quote": pick_example(visible, theme),
            }
        )
    out = pd.DataFrame(rows)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    out.to_csv(OUT, index=False)

    hidden = pd.read_csv(TICKETS, usecols=["ticket_id", "theme"])
    scored = visible.merge(hidden, on="ticket_id", how="inner")
    acc = float((scored["voc_theme"] == scored["theme"]).mean()) if len(scored) else 0.0

    print(f"wrote {OUT}")
    print(out.to_string(index=False))
    print(
        f"codebook vs hidden theme accuracy: {acc:.1%} "
        "(scoring only; not a Lola metric; tickets are SAMPLE)"
    )
    top = out.sort_values("volume", ascending=False).iloc[0]
    print(
        f"friction named: {top['theme']} "
        f"({top['volume']} of {len(visible)} tickets) — "
        "site CVR in the pulse is the same week window"
    )


if __name__ == "__main__":
    main()
