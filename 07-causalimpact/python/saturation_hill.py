#!/usr/bin/env python3
"""SAMPLE Hill / diminishing-returns chart from a documented formula.

Not Robyn output. Saturation is an MMM assumption; CausalImpact is a
time-series intervention.
"""
from __future__ import annotations

import sys
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
OUT = ROOT / "out"
OUT.mkdir(parents=True, exist_ok=True)

# Documented Hill (Hill 1910; the same algebraic form used as an MMM
# saturation curve — e.g. response = β * x^α / (x^α + γ^α)).
# SAMPLE parameters, not estimated, not Robyn, not Meridian.
BETA_VMAX = 100.0  # max response index
GAMMA_HALF = 40_000.0  # weekly spend at 50% of max (half-saturation)
ALPHA_SHAPE = 1.6  # α = 1 is Michaelis–Menten; α > 1 is an S-curve
SPEND_MAX = 120_000.0


def hill(spend: np.ndarray, beta: float, gamma: float, alpha: float) -> np.ndarray:
    """f(x) = β * x^α / (x^α + γ^α)."""
    x_a = np.power(np.maximum(spend, 0.0), alpha)
    g_a = gamma ** alpha
    return beta * x_a / (x_a + g_a)


def main() -> int:
    spend = np.linspace(0.0, SPEND_MAX, 400)
    response = hill(spend, BETA_VMAX, GAMMA_HALF, ALPHA_SHAPE)
    half = hill(np.array([GAMMA_HALF]), BETA_VMAX, GAMMA_HALF, ALPHA_SHAPE)[0]

    fig, ax = plt.subplots(figsize=(9.5, 5.6), constrained_layout=True)
    ax.plot(spend / 1000.0, response, color="#1d4ed8", lw=2.2, label="Hill response (SAMPLE formula)")
    ax.axvline(GAMMA_HALF / 1000.0, color="#ea580c", ls="--", lw=1.2, label=f"Half-saturation γ = ${GAMMA_HALF:,.0f}/wk")
    ax.axhline(half, color="#9ca3af", ls=":", lw=1.0)
    ax.scatter([GAMMA_HALF / 1000.0], [half], color="#ea580c", zorder=5)
    ax.set_xlabel("Weekly spend ($ thousands, SAMPLE)")
    ax.set_ylabel("Response index (max 100)")
    ax.set_title("SAMPLE: Hill diminishing returns (documented formula, not Robyn output)")
    ax.legend(loc="lower right", fontsize=8)
    ax.grid(True, alpha=0.3)
    ax.set_xlim(0, SPEND_MAX / 1000.0)
    ax.set_ylim(0, BETA_VMAX * 1.05)
    fig.text(
        0.01,
        0.01,
        "SAMPLE caption: saturation is an MMM assumption; CausalImpact is a time-series intervention. "
        "f(x)=β x^α/(x^α+γ^α) with β=100, γ=40000, α=1.6.",
        fontsize=8,
        color="#374151",
    )
    path = OUT / "SAMPLE_hill_saturation.png"
    fig.savefig(path, dpi=140)
    plt.close(fig)
    print(f"Hill formula: f(x) = {BETA_VMAX:g} * x^{ALPHA_SHAPE} / (x^{ALPHA_SHAPE} + {GAMMA_HALF:g}^{ALPHA_SHAPE})")
    print(f"Half-saturation response at γ: {half:.1f} / {BETA_VMAX:g}")
    print(f"Wrote {path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
