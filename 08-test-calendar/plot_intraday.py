#!/usr/bin/env python3
"""SAMPLE plot: 11:00, MER below break-even for 3 hours → cut."""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd

HERE = Path(__file__).resolve().parent
OUT = HERE / "out"
CSV = OUT / "intraday_sample.csv"
PNG = OUT / "SAMPLE_intraday_mer_cut.png"


def ensure_csv() -> None:
    if not CSV.exists():
        subprocess.check_call([sys.executable, str(HERE / "generate_intraday.py")])


def main() -> int:
    ensure_csv()
    df = pd.read_csv(CSV)
    be = float(df["break_even_mer"].iloc[0])
    hours = df["hour"].to_numpy()
    fig, axes = plt.subplots(2, 1, figsize=(10.5, 7.4), sharex=True, constrained_layout=True)

    ax = axes[0]
    ax.bar(hours, df["spend_usd"], color="#93c5fd", width=0.7, label="Hourly spend")
    ax.plot(hours, df["cash_proxy_usd"], color="#1d4ed8", lw=2.0, marker="o", ms=3.5, label="Hourly cash-proxy")
    ax.axvspan(10.5, 13.5, color="#fecaca", alpha=0.55, label="11:00–13:00 kill window")
    ax.set_ylabel("USD (SAMPLE)")
    ax.set_title("SAMPLE: hourly spend vs cash-proxy — one day")
    ax.legend(loc="upper left", fontsize=8)
    ax.grid(True, axis="y", alpha=0.3)

    ax = axes[1]
    ax.plot(hours, df["mer"], color="#1d4ed8", lw=2.0, marker="o", ms=4, label="Cash MER")
    ax.axhline(be, color="#ea580c", ls="--", lw=1.4, label=f"Break-even MER {be:.2f}")
    ax.axvspan(10.5, 13.5, color="#fecaca", alpha=0.55)
    ax.set_xticks(hours)
    ax.set_xticklabels(df["hour_label"], rotation=45, ha="right")
    ax.set_xlabel("Hour (SAMPLE day)")
    ax.set_ylabel("Cash MER")
    ax.set_title("SAMPLE: 11:00, MER below break-even for 3 hours → cut.")
    ax.legend(loc="upper right", fontsize=8)
    ax.grid(True, axis="y", alpha=0.3)
    ax.annotate(
        "11:00, MER below break-even for 3 hours → cut.",
        xy=(11, df.loc[df["hour"] == 11, "mer"].iloc[0]),
        xytext=(2, 1.15),
        textcoords="data",
        fontsize=9,
        color="#991b1b",
        arrowprops=dict(arrowstyle="->", color="#991b1b"),
    )
    fig.text(
        0.01,
        0.01,
        "SAMPLE. Hours, not weeks. Not a bidding bot. Kill is a same-day cut, not a 4-week geo readout.",
        fontsize=8,
        color="#374151",
    )
    fig.savefig(PNG, dpi=140)
    plt.close(fig)
    print(f"Wrote {PNG}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
