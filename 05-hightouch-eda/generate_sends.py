"""SAMPLE send-level data for the Hightouch EDA muscle folder. Seed 2020.

Not Black Clover. Not Nutricost. Not Hightouch customer data.

Clean file: 40% of users are a true email holdout (holdout_flag=1, sent=0).
Contaminated file: 15% of those holdout users actually received the email;
holdout_flag stays 1. Potential outcomes are fixed (same latent uniform),
so leaked holdout users pick up the treated conversion path.
"""
from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd

SEED = 2020
N = 12000
N_COHORTS = 8
HOLDOUT_RATE = 0.40
UNREACHABLE_RATE = 0.12
WEEKLY_SEND_CAP = 700
CONTAMINATION_RATE = 0.15
CHANNEL = "email"

ROOT = Path(__file__).resolve().parent
DATA = ROOT / "data"

COHORT_WEEKS = (
    pd.date_range("2024-01-01", periods=N_COHORTS, freq="W-MON")
    .strftime("%Y-%m-%d")
    .tolist()
)

# 4-week window baseline CR and lift among users who actually receive email.
# Cohort 0 is a promo week on purpose — lift is concentrated there.
BASE_CR = np.array([0.070, 0.040, 0.040, 0.042, 0.038, 0.041, 0.039, 0.040])
LIFT_IF_SENT = np.array([0.090, 0.018, 0.016, 0.020, 0.015, 0.018, 0.016, 0.019])


def _assign_sends(
    rng: np.random.Generator,
    holdout_flag: np.ndarray,
    reachable: np.ndarray,
    cohort_idx: np.ndarray,
) -> np.ndarray:
    sent = np.zeros(len(holdout_flag), dtype=np.int8)
    eligible = (holdout_flag == 0) & reachable
    for cohort in range(N_COHORTS):
        idx = np.flatnonzero(eligible & (cohort_idx == cohort))
        if idx.size == 0:
            continue
        if idx.size <= WEEKLY_SEND_CAP:
            sent[idx] = 1
        else:
            chosen = rng.choice(idx, size=WEEKLY_SEND_CAP, replace=False)
            sent[chosen] = 1
    return sent


def generate(seed: int = SEED) -> tuple[pd.DataFrame, pd.DataFrame]:
    rng = np.random.default_rng(seed)
    n_per = N // N_COHORTS
    cohort_idx = np.repeat(np.arange(N_COHORTS), n_per)
    user_id = np.arange(1, N + 1)

    holdout_flag = np.zeros(N, dtype=np.int8)
    n_hold = int(round(HOLDOUT_RATE * N))
    holdout_flag[:n_hold] = 1
    rng.shuffle(holdout_flag)

    reachable = rng.random(N) >= UNREACHABLE_RATE
    sent = _assign_sends(rng, holdout_flag, reachable, cohort_idx)

    p_base = BASE_CR[cohort_idx]
    p_sent = np.clip(p_base + LIFT_IF_SENT[cohort_idx], 0.0, 1.0)
    latent = rng.random(N)
    y0 = (latent < p_base).astype(np.int8)
    y1 = (latent < p_sent).astype(np.int8)
    converted = np.where(sent == 1, y1, y0).astype(np.int8)

    aov = np.clip(np.round(np.exp(rng.normal(np.log(48.0), 0.35, N)), 2), 12.0, 180.0)
    revenue = np.where(converted == 1, aov, 0.0)

    clean = pd.DataFrame(
        {
            "user_id": user_id,
            "cohort_week": [COHORT_WEEKS[i] for i in cohort_idx],
            "channel": CHANNEL,
            "sent": sent.astype(int),
            "converted": converted.astype(int),
            "revenue": np.round(revenue, 2),
            "holdout_flag": holdout_flag.astype(int),
        }
    )

    dirty = clean.copy()
    hold_idx = np.flatnonzero(holdout_flag == 1)
    n_leak = int(round(CONTAMINATION_RATE * hold_idx.size))
    leak = rng.choice(hold_idx, size=n_leak, replace=False)
    sent_d = dirty["sent"].to_numpy().copy()
    conv_d = dirty["converted"].to_numpy().copy()
    rev_d = dirty["revenue"].to_numpy().copy()
    sent_d[leak] = 1
    conv_d[leak] = y1[leak]
    rev_d[leak] = np.where(y1[leak] == 1, aov[leak], 0.0)
    dirty["sent"] = sent_d
    dirty["converted"] = conv_d
    dirty["revenue"] = np.round(rev_d, 2)
    return clean, dirty


def main() -> None:
    DATA.mkdir(parents=True, exist_ok=True)
    clean, dirty = generate()
    clean_path = DATA / "sends.csv"
    dirty_path = DATA / "sends_contaminated.csv"
    clean.to_csv(clean_path, index=False)
    dirty.to_csv(dirty_path, index=False)
    n_hold = int((clean["holdout_flag"] == 1).sum())
    n_leak = int(((dirty["holdout_flag"] == 1) & (dirty["sent"] == 1)).sum())
    print(
        f"SAMPLE wrote {len(clean)} rows -> {clean_path.name}; "
        f"holdout={n_hold} ({n_hold / len(clean):.1%}); "
        f"contaminated holdout sent={n_leak} ({n_leak / n_hold:.1%}) -> {dirty_path.name}"
    )


if __name__ == "__main__":
    main()
