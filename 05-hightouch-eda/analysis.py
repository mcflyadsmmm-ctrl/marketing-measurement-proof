"""SAMPLE incrementality EDA for the Hightouch take-home muscle.

Polars for load and group_by. Clean holdout vs contaminated holdout.
Not a SHAP notebook. Not a reward-function agent. Not Zip ML theater.
"""
from __future__ import annotations

from pathlib import Path

import duckdb
import matplotlib.pyplot as plt
import numpy as np
import polars as pl

plt.switch_backend("Agg")

ROOT = Path(__file__).resolve().parent
DATA = ROOT / "data"
OUT = ROOT / "out"
SQL_PATH = ROOT / "sql" / "incremental_cr.sql"
CLEAN_CSV = DATA / "sends.csv"
DIRTY_CSV = DATA / "sends_contaminated.csv"

BOOT_SEED = 2020
N_BOOT = 2000
Z_WILSON = 1.96
HOLDOUT_SEND_KILL = 0.01


def wilson_interval(k: int, n: int, z: float = Z_WILSON) -> tuple[float, float]:
    if n <= 0:
        return (float("nan"), float("nan"))
    p = k / n
    z2 = z * z
    denom = 1.0 + z2 / n
    center = (p + z2 / (2.0 * n)) / denom
    inner = p * (1.0 - p) / n + z2 / (4.0 * n * n)
    margin = z * (inner ** 0.5) / denom
    return (max(0.0, center - margin), min(1.0, center + margin))


def bootstrap_diff_ci(
    treated: np.ndarray,
    holdout: np.ndarray,
    rng: np.random.Generator,
    n_boot: int = N_BOOT,
) -> tuple[float, float]:
    t = rng.choice(treated, size=(n_boot, treated.size), replace=True).mean(axis=1)
    h = rng.choice(holdout, size=(n_boot, holdout.size), replace=True).mean(axis=1)
    lo, hi = np.quantile(t - h, [0.025, 0.975])
    return float(lo), float(hi)


def load_sends(path: Path) -> pl.DataFrame:
    return pl.read_csv(path)


def arm_summary(df: pl.DataFrame) -> pl.DataFrame:
    return (
        df.group_by("holdout_flag")
        .agg(
            n=pl.len(),
            n_sent=pl.col("sent").sum(),
            sent_rate=pl.col("sent").mean(),
            conversions=pl.col("converted").sum(),
            cr=pl.col("converted").mean(),
            revenue=pl.col("revenue").sum(),
            revenue_per_user=pl.col("revenue").mean(),
        )
        .sort("holdout_flag")
    )


def cohort_summary(df: pl.DataFrame) -> pl.DataFrame:
    """4-week window revenue and CR by cohort_week × holdout_flag.

    converted / revenue on the file are already 4-week post-cohort outcomes.
    """
    g = (
        df.group_by(["cohort_week", "holdout_flag"])
        .agg(
            n=pl.len(),
            n_sent=pl.col("sent").sum(),
            conversions=pl.col("converted").sum(),
            cr=pl.col("converted").mean(),
            revenue=pl.col("revenue").sum(),
            revenue_per_user=pl.col("revenue").mean(),
        )
        .sort(["cohort_week", "holdout_flag"])
    )
    treated = g.filter(pl.col("holdout_flag") == 0)
    holdout = g.filter(pl.col("holdout_flag") == 1)
    return treated.join(holdout, on="cohort_week", suffix="_holdout").with_columns(
        incremental_cr=pl.col("cr") - pl.col("cr_holdout"),
        incremental_revenue=pl.col("revenue") - pl.col("revenue_holdout"),
        incremental_rev_per_user=pl.col("revenue_per_user")
        - pl.col("revenue_per_user_holdout"),
    )


def lift_metrics(df: pl.DataFrame, dataset: str) -> dict:
    arms = arm_summary(df)
    treated = arms.filter(pl.col("holdout_flag") == 0)
    holdout = arms.filter(pl.col("holdout_flag") == 1)
    t_n = int(treated["n"][0])
    h_n = int(holdout["n"][0])
    t_k = int(treated["conversions"][0])
    h_k = int(holdout["conversions"][0])
    t_cr = float(treated["cr"][0])
    h_cr = float(holdout["cr"][0])
    t_wilson = wilson_interval(t_k, t_n)
    h_wilson = wilson_interval(h_k, h_n)
    t_y = df.filter(pl.col("holdout_flag") == 0).get_column("converted").to_numpy()
    h_y = df.filter(pl.col("holdout_flag") == 1).get_column("converted").to_numpy()
    rng = np.random.default_rng(BOOT_SEED)
    ci_lo, ci_hi = bootstrap_diff_ci(t_y, h_y, rng)
    return {
        "dataset": dataset,
        "treated_n": t_n,
        "holdout_n": h_n,
        "treated_sent_rate": float(treated["sent_rate"][0]),
        "holdout_sent_rate": float(holdout["sent_rate"][0]),
        "treated_cr": t_cr,
        "holdout_cr": h_cr,
        "treated_cr_wilson_low": t_wilson[0],
        "treated_cr_wilson_high": t_wilson[1],
        "holdout_cr_wilson_low": h_wilson[0],
        "holdout_cr_wilson_high": h_wilson[1],
        "incremental_cr": t_cr - h_cr,
        "incremental_cr_ci_low": ci_lo,
        "incremental_cr_ci_high": ci_hi,
        "ci_method": f"bootstrap_percentile_B{N_BOOT}_seed{BOOT_SEED}",
        "treated_revenue": float(treated["revenue"][0]),
        "holdout_revenue": float(holdout["revenue"][0]),
        "treated_rev_per_user": float(treated["revenue_per_user"][0]),
        "holdout_rev_per_user": float(holdout["revenue_per_user"][0]),
        "incremental_rev_per_user": float(treated["revenue_per_user"][0])
        - float(holdout["revenue_per_user"][0]),
    }


def run_sql_incremental_cr(csv_path: Path) -> dict:
    sql = SQL_PATH.read_text().replace("data/sends.csv", csv_path.as_posix())
    row = duckdb.sql(sql).fetchone()
    cols = [
        "treated_n",
        "holdout_n",
        "treated_conversions",
        "holdout_conversions",
        "treated_cr",
        "holdout_cr",
        "incremental_cr",
    ]
    return dict(zip(cols, row))


def write_marketer(clean: dict, dirty: dict, cohort: pl.DataFrame) -> str:
    top = cohort.sort("incremental_rev_per_user", descending=True).row(0, named=True)
    pct_dirty = 100.0 * dirty["holdout_sent_rate"]
    text = (
        "I would not ship this send.\n\n"
        "On the clean holdout, the email looks incremental: treated conversion "
        f"rate {clean['treated_cr']:.2%} vs holdout {clean['holdout_cr']:.2%}, "
        f"incremental CR {clean['incremental_cr']:.2%} (95% bootstrap CI "
        f"{clean['incremental_cr_ci_low']:.2%} to {clean['incremental_cr_ci_high']:.2%}) "
        "on a 4-week window. That is the number I would take to a marketer if "
        "the holdout were a holdout.\n\n"
        f"It is not. In the contaminated file, {pct_dirty:.0f}% of users with "
        "holdout_flag=1 still have sent=1 — they actually received the email. "
        f"Holdout CR rises from {clean['holdout_cr']:.2%} to {dirty['holdout_cr']:.2%} "
        "and incremental CR collapses from "
        f"{clean['incremental_cr']:.2%} to {dirty['incremental_cr']:.2%} "
        f"(CI {dirty['incremental_cr_ci_low']:.2%} to "
        f"{dirty['incremental_cr_ci_high']:.2%}). The creative did not get worse. "
        "The counterfactual got polluted.\n\n"
        "Kill rule: if send rate among holdout_flag=1 is above 1%, stop. Do not "
        "scale. Do not retune the agent. Fix suppression and assignment, then "
        "rerun. A smaller lift on a dirty holdout is not evidence the campaign "
        "should stay on; it is evidence you can no longer measure it. Even on "
        "the clean file, most incremental cash sits in cohort "
        f"{top['cohort_week']} — I would not turn this into always-on without "
        "a replicate on a later cohort."
    )
    return text


def plot_lift(clean: dict, dirty: dict, path: Path) -> None:
    fig, ax = plt.subplots(figsize=(8.0, 4.6))
    xs = [0, 1]
    ys = [clean["incremental_cr"], dirty["incremental_cr"]]
    yerr = np.array(
        [
            [
                clean["incremental_cr"] - clean["incremental_cr_ci_low"],
                dirty["incremental_cr"] - dirty["incremental_cr_ci_low"],
            ],
            [
                clean["incremental_cr_ci_high"] - clean["incremental_cr"],
                dirty["incremental_cr_ci_high"] - dirty["incremental_cr"],
            ],
        ]
    )
    ax.bar(
        xs,
        ys,
        yerr=yerr,
        capsize=6,
        color=["#2c6e49", "#bc4749"],
        error_kw={"ecolor": "#1d1d1d", "elinewidth": 1.2},
    )
    ax.axhline(0.0, color="#333333", linewidth=0.8)
    ax.set_xticks(xs, ["Clean holdout", "Contaminated holdout"])
    ax.set_ylabel("Incremental conversion rate")
    ax.set_title("SAMPLE: incremental CR, clean vs contaminated holdout")
    ax.set_ylim(min(-0.005, min(ys) - 0.01), max(ys) + 0.02)
    fig.tight_layout()
    fig.savefig(path, dpi=140)
    plt.close(fig)


def _print_block(title: str, frame: pl.DataFrame) -> None:
    print(f"\n=== {title} ===")
    print(frame)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    if not CLEAN_CSV.exists() or not DIRTY_CSV.exists():
        raise FileNotFoundError(
            "Missing data/sends.csv or data/sends_contaminated.csv. "
            "Run generate_sends.py first."
        )

    clean_df = load_sends(CLEAN_CSV)
    dirty_df = load_sends(DIRTY_CSV)

    _print_block("SAMPLE clean arms (Polars group_by holdout_flag)", arm_summary(clean_df))
    clean_cohort = cohort_summary(clean_df)
    _print_block("SAMPLE clean 4-week cohort revenue × holdout", clean_cohort)

    clean = lift_metrics(clean_df, "sends.csv")
    dirty = lift_metrics(dirty_df, "sends_contaminated.csv")
    sql_row = run_sql_incremental_cr(CLEAN_CSV)
    delta = abs(sql_row["incremental_cr"] - clean["incremental_cr"])
    if delta > 1e-12:
        raise RuntimeError(
            f"DuckDB SQL incremental CR {sql_row['incremental_cr']} "
            f"!= Polars {clean['incremental_cr']}"
        )

    pl.DataFrame([clean]).write_csv(OUT / "clean_lift.csv")
    pl.DataFrame([dirty]).write_csv(OUT / "contaminated_lift.csv")
    plot_lift(clean, dirty, OUT / "sample_incremental_cr.png")

    print("\n=== SAMPLE incremental CR ===")
    print(
        f"clean: {clean['incremental_cr']:.4%} "
        f"[{clean['incremental_cr_ci_low']:.4%}, {clean['incremental_cr_ci_high']:.4%}] "
        f"holdout_sent_rate={clean['holdout_sent_rate']:.2%}"
    )
    print(
        f"contaminated: {dirty['incremental_cr']:.4%} "
        f"[{dirty['incremental_cr_ci_low']:.4%}, {dirty['incremental_cr_ci_high']:.4%}] "
        f"holdout_sent_rate={dirty['holdout_sent_rate']:.2%}"
    )
    print(
        f"DuckDB SQL matches Polars incremental CR on clean file "
        f"({sql_row['incremental_cr']:.6%})."
    )
    if dirty["holdout_sent_rate"] > HOLDOUT_SEND_KILL:
        print(
            "ESTIMATE BREAKS: holdout_flag=1 still received email "
            f"({dirty['holdout_sent_rate']:.1%} sent). Kill the read."
        )

    dirty_cohort = cohort_summary(dirty_df)
    _print_block("SAMPLE contaminated 4-week cohort revenue × holdout", dirty_cohort)

    paragraph = write_marketer(clean, dirty, clean_cohort)
    (OUT / "marketer.md").write_text(paragraph + "\n", encoding="utf-8")
    print("\n=== SAMPLE marketer paragraph (out/marketer.md) ===")
    print(paragraph)


if __name__ == "__main__":
    main()
