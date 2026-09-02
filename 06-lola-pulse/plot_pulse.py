#!/usr/bin/env python3
"""SAMPLE matplotlib pulse dashboard. Not Lola data."""

from __future__ import annotations

from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.dates as mdates
import matplotlib.pyplot as plt
import pandas as pd
from matplotlib.patches import Patch

HERE = Path(__file__).resolve().parent
PULSE = HERE / "out" / "pulse_table.csv"
PNG = HERE / "out" / "pulse.png"

SHIPPING_START = pd.Timestamp("2025-07-07")
SHIPPING_END = pd.Timestamp("2025-08-18")
TITLE = "SAMPLE: weekly cash MER and spend (not Lola data)"


def _shade(ax, start: pd.Timestamp, end: pd.Timestamp, color: str, alpha: float) -> None:
    ax.axvspan(start, end, color=color, alpha=alpha, zorder=0)


def main() -> None:
    if not PULSE.exists():
        raise SystemExit(f"missing {PULSE}; run generate_pulse.py first")

    df = pd.read_csv(PULSE, parse_dates=["week"])
    df = df.sort_values("week")
    x = df["week"]
    be = float(df["break_even_mer"].iloc[0])

    fig, axes = plt.subplots(2, 2, figsize=(13.5, 8.8), sharex=True)
    fig.suptitle(TITLE, fontsize=14, fontweight="bold", y=0.98)

    mer_ax, spend_ax, email_ax, cvr_ax = axes.ravel()

    for ax in (mer_ax, spend_ax, email_ax, cvr_ax):
        _shade(ax, SHIPPING_START, SHIPPING_END, "#f4c7c3", 0.45)
        for _, row in df.iterrows():
            if isinstance(row["annotation"], str) and row["annotation"].strip():
                ax.axvline(row["week"], color="#7a7a7a", ls=":", lw=0.8, alpha=0.8)

    mer_ax.plot(x, df["cash_mer"], color="#1f4e79", lw=2.0, label="cash MER")
    mer_ax.axhline(be, color="#666666", ls="--", lw=1.2, label=f"SAMPLE break-even {be:.1f}")
    mer_ax.set_ylabel("cash MER")
    mer_ax.set_title("Spine: cash MER (net cash / paid spend)")
    mer_ax.legend(loc="upper right", fontsize=8, frameon=False)

    spend_ax.bar(x, df["paid_spend"] / 1000.0, width=6, color="#5b8fa8", alpha=0.9, label="paid spend")
    spend_ax.set_ylabel("paid spend ($k)")
    spend_ax.set_title("Paid spend paced against MER, not last-click")
    spend_ax.legend(loc="upper left", fontsize=8, frameon=False)

    email_ax.plot(
        x,
        df["email_lastclick_share"] * 100.0,
        color="#c45911",
        lw=2.0,
        label="email last-click share of cash",
    )
    email_ax.set_ylabel("share of cash (%)")
    email_ax.set_title("Distrusted: last-click email share rises when MER falls")
    email_ax.legend(loc="upper left", fontsize=8, frameon=False)

    cvr_ax.plot(x, df["site_cvr"] * 100.0, color="#2e7d32", lw=2.0, label="site CVR")
    cvr_ax.set_ylabel("site CVR (%)")
    cvr_ax.set_title("VoC bridge: shipping window (shaded) drops conversion")
    cvr_ax.legend(loc="upper left", fontsize=8, frameon=False)

    locator = mdates.MonthLocator(interval=2)
    fmt = mdates.DateFormatter("%b %Y")
    for ax in (mer_ax, spend_ax, email_ax, cvr_ax):
        ax.xaxis.set_major_locator(locator)
        ax.xaxis.set_major_formatter(fmt)
        ax.grid(True, axis="y", alpha=0.3)
        ax.set_xlim(x.min(), x.max())

    for label in cvr_ax.get_xticklabels() + spend_ax.get_xticklabels():
        label.set_rotation(30)
        label.set_ha("right")
    for label in mer_ax.get_xticklabels() + email_ax.get_xticklabels():
        label.set_visible(False)

    # Callouts that match pulse_table.csv annotations (same story).
    mer_row = df.loc[df["week"] == pd.Timestamp("2025-03-10")].iloc[0]
    mer_ax.annotate(
        "email last-click\nlied; cash did not",
        xy=(mer_row["week"], float(mer_row["cash_mer"])),
        xytext=(pd.Timestamp("2024-08-12"), float(df["cash_mer"].min()) + 0.12),
        fontsize=7.5,
        color="#1f4e79",
        arrowprops={"arrowstyle": "->", "color": "#1f4e79", "lw": 0.8},
    )
    cvr_ax.annotate(
        "shipping friction\n(see VoC table)",
        xy=(pd.Timestamp("2025-07-14"), float(df.loc[df["week"] == pd.Timestamp("2025-07-14"), "site_cvr"].iloc[0]) * 100.0),
        xytext=(pd.Timestamp("2024-10-07"), 1.45),
        fontsize=7.5,
        color="#9c2a2a",
        arrowprops={"arrowstyle": "->", "color": "#9c2a2a", "lw": 0.8},
    )

    ship_patch = Patch(facecolor="#f4c7c3", edgecolor="none", label="SAMPLE shipping-ticket window")
    fig.legend(handles=[ship_patch], loc="lower left", bbox_to_anchor=(0.08, 0.01), frameon=False, fontsize=8)
    fig.text(
        0.99,
        0.01,
        "SAMPLE synthetic series. Not Lola Blankets data. Not a live VoC. Tableau/Looker screenshot later; this PNG is the artifact.",
        ha="right",
        fontsize=7,
        color="#555555",
    )
    fig.tight_layout(rect=[0.02, 0.05, 0.99, 0.95])
    PNG.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(PNG, dpi=140)
    plt.close(fig)
    print(f"wrote {PNG}")
    print(f"title: {TITLE}")


if __name__ == "__main__":
    main()
