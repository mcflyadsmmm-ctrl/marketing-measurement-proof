#!/usr/bin/env python3
"""SAMPLE national series + pre-period regression.

This Python is not Brodersen. R CausalImpact is the named library once R exists
(see ../R/run_causalimpact.R). Pre-period / post-period are declared BEFORE fit.

DGP (locked): +12% cash from week 80. Failure design lies and starts post at week 60.
"""
from __future__ import annotations

import sys
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import statsmodels.api as sm

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
OUT = ROOT / "out"
OUT.mkdir(parents=True, exist_ok=True)

SEED = 20260901
N_WEEKS = 104
TRUE_INTERVENTION_WEEK = 80
WRONG_INTERVENTION_WEEK = 60
TRUE_LIFT = 0.12
N_BOOT = 2000
ALPHA = 0.05

# Declared BEFORE any fit. Do not edit after looking at post-period plots.
GOOD_PRE = (1, TRUE_INTERVENTION_WEEK - 1)  # weeks 1–79
GOOD_POST = (TRUE_INTERVENTION_WEEK, N_WEEKS)  # weeks 80–104
BAD_PRE = (1, WRONG_INTERVENTION_WEEK - 1)  # weeks 1–59
BAD_POST = (WRONG_INTERVENTION_WEEK, N_WEEKS)  # weeks 60–104

CAPTION = (
    "SAMPLE. This Python is not Brodersen; R CausalImpact is the named library "
    "once R exists."
)


def generate_series(rng: np.random.Generator) -> pd.DataFrame:
    """National weekly cash with untreated covariates and a known week-80 shock."""
    week = np.arange(1, N_WEEKS + 1)
    week_start = pd.date_range("2024-01-01", periods=N_WEEKS, freq="W-MON")
    seasonal = np.sin(2.0 * np.pi * week / 52.0)
    seasonal_c = np.cos(2.0 * np.pi * week / 52.0)
    x_search = 100.0 + 0.15 * week + 8.0 * seasonal + rng.normal(0.0, 2.0, N_WEEKS)
    x_category = 80.0 + 0.08 * week + 5.0 * seasonal_c + rng.normal(0.0, 1.5, N_WEEKS)
    # ~4% residual on a ~55k base so the 95% CI is not a 0.4pp toy interval.
    noise = rng.normal(0.0, 2200.0, N_WEEKS)
    base = 50_000.0 + 45.0 * x_search + 30.0 * x_category + noise
    treated = (week >= TRUE_INTERVENTION_WEEK).astype(int)
    y = base * (1.0 + TRUE_LIFT * treated)
    return pd.DataFrame(
        {
            "week": week,
            "week_start": week_start,
            "y_cash": y,
            "x_search_index": x_search,
            "x_category_demand": x_category,
            "true_treated": treated,
            "true_lift": TRUE_LIFT * treated,
        }
    )


def _design(df: pd.DataFrame) -> np.ndarray:
    return np.column_stack(
        [df["x_search_index"].to_numpy(), df["x_category_demand"].to_numpy()]
    )


def fit_preperiod(df: pd.DataFrame, pre: tuple[int, int], post: tuple[int, int]) -> dict:
    """OLS y ~ search + category on the declared pre-period only; predict all weeks."""
    pre_mask = (df["week"] >= pre[0]) & (df["week"] <= pre[1])
    post_mask = (df["week"] >= post[0]) & (df["week"] <= post[1])
    y = df["y_cash"].to_numpy()
    x = _design(df)
    x_pre = sm.add_constant(x[pre_mask], has_constant="add")
    x_all = sm.add_constant(x, has_constant="add")
    model = sm.OLS(y[pre_mask], x_pre).fit()
    pred = model.get_prediction(x_all)
    frame = pred.summary_frame(alpha=ALPHA)
    yhat = frame["mean"].to_numpy()
    mean_lo = frame["mean_ci_lower"].to_numpy()
    mean_hi = frame["mean_ci_upper"].to_numpy()
    effect = y - yhat
    # effect = y - yhat, so CI flips the mean interval
    effect_lo = y - mean_hi
    effect_hi = y - mean_lo
    cum = np.cumsum(effect)
    return {
        "model": model,
        "pre_mask": pre_mask.to_numpy(),
        "post_mask": post_mask.to_numpy(),
        "y": y,
        "yhat": yhat,
        "mean_lo": mean_lo,
        "mean_hi": mean_hi,
        "effect": effect,
        "effect_lo": effect_lo,
        "effect_hi": effect_hi,
        "cumulative": cum,
        "x_all": x_all,
    }


def residual_bootstrap_post(fit: dict, rng: np.random.Generator, n_boot: int = N_BOOT):
    """Refit on residual-resampled pre-period; y_post stays the observed series."""
    pre = fit["pre_mask"]
    post = fit["post_mask"]
    y = fit["y"]
    x_pre = fit["x_all"][pre]
    x_post = fit["x_all"][post]
    yhat_pre = fit["yhat"][pre]
    resid = y[pre] - yhat_pre
    y_post = y[post]
    ates = np.empty(n_boot)
    rels = np.empty(n_boot)
    cums = np.empty(n_boot)
    paths = np.empty((n_boot, int(post.sum())))
    for i in range(n_boot):
        y_star = yhat_pre + rng.choice(resid, size=resid.size, replace=True)
        beta = sm.OLS(y_star, x_pre).fit().params
        yhat_p = x_post @ beta
        eff = y_post - yhat_p
        ates[i] = eff.mean()
        rels[i] = np.mean(eff / yhat_p)
        cums[i] = eff.sum()
        paths[i] = np.cumsum(eff)
    return ates, rels, cums, paths


def bootstrap_post(fit: dict, rng: np.random.Generator) -> dict:
    """Honest 95% CI from residual bootstrap (not Brodersen posterior)."""
    post = fit["post_mask"]
    y_post = fit["y"][post]
    yhat_hat = fit["yhat"][post]
    eff_hat = y_post - yhat_hat
    ates, rels, cums, _paths = residual_bootstrap_post(fit, rng, N_BOOT)
    lo, hi = 100 * ALPHA / 2.0, 100 * (1.0 - ALPHA / 2.0)
    return {
        "ate": float(eff_hat.mean()),
        "ate_lo": float(np.percentile(ates, lo)),
        "ate_hi": float(np.percentile(ates, hi)),
        "rel": float(np.mean(eff_hat / yhat_hat)),
        "rel_lo": float(np.percentile(rels, lo)),
        "rel_hi": float(np.percentile(rels, hi)),
        "cum": float(eff_hat.sum()),
        "cum_lo": float(np.percentile(cums, lo)),
        "cum_hi": float(np.percentile(cums, hi)),
        "n_post": int(post.sum()),
    }


def slice_relative(fit: dict, week: np.ndarray, start: int, end: int) -> float:
    mask = (week >= start) & (week <= end)
    yhat = fit["yhat"][mask]
    return float(np.mean((fit["y"][mask] - yhat) / yhat))


def fmt_pct(x: float) -> str:
    return f"{100.0 * x:.1f}%"


def fmt_money(x: float) -> str:
    sign = "-" if x < 0 else ""
    return f"{sign}${abs(x):,.0f}"


def plot_panels(df: pd.DataFrame, fit: dict, title: str, path: Path) -> None:
    week = df["week"].to_numpy()
    post = fit["post_mask"]
    fig, axes = plt.subplots(3, 1, figsize=(10.5, 9.2), sharex=True, constrained_layout=True)
    ax = axes[0]
    ax.plot(week, fit["y"], color="#1d4ed8", lw=1.6, label="Actual cash")
    ax.plot(week, fit["yhat"], color="#ea580c", lw=1.6, label="Predicted (pre-period fit)")
    ax.fill_between(week, fit["mean_lo"], fit["mean_hi"], color="#fdba74", alpha=0.45, label="95% CI (mean)")
    ax.axvline(week[post][0], color="#111827", ls="--", lw=1.0, label="Declared intervention")
    ax.set_ylabel("Weekly cash (SAMPLE)")
    ax.set_title(title)
    ax.legend(loc="upper left", fontsize=8)
    ax.grid(True, alpha=0.3)

    ax = axes[1]
    ax.plot(week, fit["effect"], color="#1d4ed8", lw=1.4)
    ax.fill_between(week, fit["effect_lo"], fit["effect_hi"], color="#93c5fd", alpha=0.5)
    ax.axhline(0.0, color="#6b7280", lw=0.8)
    ax.axvline(week[post][0], color="#111827", ls="--", lw=1.0)
    ax.set_ylabel("Pointwise gap")
    ax.set_title("SAMPLE: pointwise actual − predicted (95% CI)")
    ax.grid(True, alpha=0.3)

    # Cumulative from the start of the declared post period
    cum = np.zeros_like(fit["effect"])
    cum_lo = np.zeros_like(cum)
    cum_hi = np.zeros_like(cum)
    if post.any():
        post_eff = fit["effect"].copy()
        post_eff[~post] = 0.0
        cum = np.cumsum(post_eff)
        _ates, _rels, _cums, paths = residual_bootstrap_post(
            fit, np.random.default_rng(SEED + 7), n_boot=800
        )
        cum_lo[post] = np.percentile(paths, 2.5, axis=0)
        cum_hi[post] = np.percentile(paths, 97.5, axis=0)

    ax = axes[2]
    ax.plot(week, cum, color="#1d4ed8", lw=1.4)
    ax.fill_between(week, cum_lo, cum_hi, color="#93c5fd", alpha=0.5)
    ax.axhline(0.0, color="#6b7280", lw=0.8)
    ax.axvline(week[post][0], color="#111827", ls="--", lw=1.0)
    ax.set_xlabel("Week")
    ax.set_ylabel("Cumulative gap (post)")
    ax.set_title("SAMPLE: cumulative incremental cash from declared start (95% CI)")
    ax.grid(True, alpha=0.3)
    fig.text(0.01, 0.01, CAPTION, fontsize=8, color="#374151")
    fig.savefig(path, dpi=140)
    plt.close(fig)


def write_good_md(stats: dict, model) -> None:
    path = OUT / "good_design.md"
    contains_true = stats["rel_lo"] <= TRUE_LIFT <= stats["rel_hi"]
    excludes_zero = stats["rel_lo"] > 0.0
    path.write_text(
        "\n".join(
            [
                "# SAMPLE: good design — intervention week locked before fit",
                "",
                CAPTION,
                "",
                "Pre-period and post-period were declared **before** fitting. They were not chosen from the post-period plot.",
                "",
                "| Lock | Value |",
                "|---|---|",
                f"| Pre-period (declared) | weeks {GOOD_PRE[0]}–{GOOD_PRE[1]} |",
                f"| Post-period (declared) | weeks {GOOD_POST[0]}–{GOOD_POST[1]} |",
                f"| True DGP intervention | week {TRUE_INTERVENTION_WEEK} |",
                f"| True DGP lift | {fmt_pct(TRUE_LIFT)} multiplicative on cash |",
                f"| Post weeks | {stats['n_post']} |",
                "",
                "## Recovered effect (pre-period OLS on untreated covariates)",
                "",
                f"- Average relative lift: **{fmt_pct(stats['rel'])}** (95% CI {fmt_pct(stats['rel_lo'])} to {fmt_pct(stats['rel_hi'])}).",
                f"- Average weekly gap: **{fmt_money(stats['ate'])}** (95% CI {fmt_money(stats['ate_lo'])} to {fmt_money(stats['ate_hi'])}).",
                f"- Cumulative post gap: **{fmt_money(stats['cum'])}** (95% CI {fmt_money(stats['cum_lo'])} to {fmt_money(stats['cum_hi'])}).",
                f"- Interval contains the known +12%: **{'yes' if contains_true else 'no'}**.",
                f"- Interval excludes zero: **{'yes' if excludes_zero else 'no'}**.",
                "",
                f"OLS R² on the pre-period: {model.rsquared:.3f}. Covariates: SAMPLE search index, SAMPLE category demand (not treated). 95% CI is a residual bootstrap of the pre-period OLS — not a Brodersen posterior. A live Firefox series would be noisier still; do not quote this interval as a W-2 result.",
                "",
                "This is the design you can defend: date locked, covariates untreated, honest CI. GeoLift is still the tool when you can hold out markets. This is the national-series alternative Mozilla asks about.",
                "",
            ]
        )
        + "\n",
        encoding="utf-8",
    )


def write_fail_md(stats: dict, rel_60_79: float) -> None:
    path = OUT / "failure_moved_date.md"
    excludes_zero = stats["rel_lo"] > 0.0
    path.write_text(
        "\n".join(
            [
                "# SAMPLE: failure case — intervention date moved after the fact",
                "",
                CAPTION,
                "",
                "**Would not ship this design.** The true shock is week 80. Declaring week 60 as the start (20 weeks early) still produces a positive “lift” because the real +12% sits inside the mis-dated post window. That is not identification. It is a date you chose after the series existed.",
                "",
                "| Lock | Value |",
                "|---|---|",
                f"| Pre-period (wrong) | weeks {BAD_PRE[0]}–{BAD_PRE[1]} |",
                f"| Post-period (wrong) | weeks {BAD_POST[0]}–{BAD_POST[1]} |",
                f"| True DGP intervention | week {TRUE_INTERVENTION_WEEK} |",
                f"| True DGP lift | {fmt_pct(TRUE_LIFT)} from week {TRUE_INTERVENTION_WEEK}, **zero** in weeks {WRONG_INTERVENTION_WEEK}–{TRUE_INTERVENTION_WEEK - 1} |",
                "",
                "## Spurious readout (same series, wrong date)",
                "",
                f"- Average relative “lift” over weeks {WRONG_INTERVENTION_WEEK}–{N_WEEKS}: **{fmt_pct(stats['rel'])}** (95% CI {fmt_pct(stats['rel_lo'])} to {fmt_pct(stats['rel_hi'])}).",
                f"- Average weekly gap: **{fmt_money(stats['ate'])}** (95% CI {fmt_money(stats['ate_lo'])} to {fmt_money(stats['ate_hi'])}).",
                f"- Cumulative gap from the fake start: **{fmt_money(stats['cum'])}** (95% CI {fmt_money(stats['cum_lo'])} to {fmt_money(stats['cum_hi'])}).",
                f"- CI excludes zero (looks “significant”): **{'yes' if excludes_zero else 'no'}**.",
                "",
                "## Why it is a lie",
                "",
                f"- Weeks {WRONG_INTERVENTION_WEEK}–{TRUE_INTERVENTION_WEEK - 1} (no DGP shock): average relative gap **{fmt_pct(rel_60_79)}** — this slice is the honest test of a week-60 start, and it is not a +12% launch.",
                f"- Weeks {TRUE_INTERVENTION_WEEK}–{N_WEEKS} still carry the real shock, so the *average* over the long fake post period is pulled positive (~ {fmt_pct(TRUE_LIFT)} × share of post weeks that are actually treated).",
                "",
                "A Firefox marketer version: if you pick the date after you see the line go up, CausalImpact will happily draw a gap. Lock the week in the test doc before anyone fits. If the date was not locked, do not ship the number.",
                "",
            ]
        )
        + "\n",
        encoding="utf-8",
    )


def main() -> int:
    rng = np.random.default_rng(SEED)
    df = generate_series(rng)
    df.to_csv(OUT / "national_weekly_sample.csv", index=False)

    good = fit_preperiod(df, GOOD_PRE, GOOD_POST)
    bad = fit_preperiod(df, BAD_PRE, BAD_POST)
    boot_rng = np.random.default_rng(SEED + 1)
    good_stats = bootstrap_post(good, boot_rng)
    bad_stats = bootstrap_post(bad, np.random.default_rng(SEED + 2))
    rel_60_79 = slice_relative(bad, df["week"].to_numpy(), WRONG_INTERVENTION_WEEK, TRUE_INTERVENTION_WEEK - 1)

    write_good_md(good_stats, good["model"])
    write_fail_md(bad_stats, rel_60_79)
    plot_panels(
        df,
        good,
        "SAMPLE: actual vs predicted — date locked at week 80 (not Brodersen)",
        OUT / "SAMPLE_actual_vs_predicted_good.png",
    )
    plot_panels(
        df,
        bad,
        "SAMPLE: failure — intervention moved to week 60 (would not ship)",
        OUT / "SAMPLE_failure_moved_date.png",
    )

    print(CAPTION)
    print(
        "GOOD locked week {tw}: rel lift {rel} (95% CI {lo} to {hi}); "
        "cum {cum}".format(
            tw=TRUE_INTERVENTION_WEEK,
            rel=fmt_pct(good_stats["rel"]),
            lo=fmt_pct(good_stats["rel_lo"]),
            hi=fmt_pct(good_stats["rel_hi"]),
            cum=fmt_money(good_stats["cum"]),
        )
    )
    print(
        "FAIL moved to week {ww}: rel “lift” {rel} (95% CI {lo} to {hi}); "
        "weeks {ww}-{cut} only {early}".format(
            ww=WRONG_INTERVENTION_WEEK,
            rel=fmt_pct(bad_stats["rel"]),
            lo=fmt_pct(bad_stats["rel_lo"]),
            hi=fmt_pct(bad_stats["rel_hi"]),
            cut=TRUE_INTERVENTION_WEEK - 1,
            early=fmt_pct(rel_60_79),
        )
    )
    print(f"Wrote {OUT / 'good_design.md'} and {OUT / 'failure_moved_date.md'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
