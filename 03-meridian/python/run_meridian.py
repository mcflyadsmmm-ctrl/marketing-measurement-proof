"""SAMPLE: Google Meridian on official national paid-media CSV.

API follows:
  https://github.com/google/meridian
  https://developers.google.com/meridian/docs/user-guide/load-national-data
  https://developers.google.com/meridian/notebook/meridian-getting-started

Python 3.11+ required. This file still documents the official sample path if
import fails on 3.9. Does not invent BudgetOptimizer numbers.
"""

from __future__ import annotations

import sys
import traceback
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "out"
NATIONAL_MEDIA_CSV = (
    "https://raw.githubusercontent.com/google/meridian/main/"
    "meridian/data/simulated_data/csv/national_media.csv"
)
CHANNELS = ["Channel0", "Channel1", "Channel2", "Channel3"]
CONTROL_COLS = [
    "competitor_activity_score_control",
    "sentiment_score_control",
]

# Laptop timebox. Production (Getting Started colab, GPU):
# n_chains=10, n_adapt=2000, n_burnin=500, n_keep=1000
N_CHAINS = 2
N_ADAPT = 200
N_BURNIN = 100
N_KEEP = 100
N_PRIOR = 100


def _write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def write_not_run_stub(reason: str) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    _write(
        OUT / "README.md",
        (
            "# SAMPLE: Meridian not run\n\n"
            f"{reason.strip()}\n\n"
            "No posterior contribution, saturation, or budget reallocation "
            "numbers were written. Do not invent optimizer dollars.\n\n"
            "Decision rule: [`decision.md`](decision.md).\n"
        ),
    )


def save_altair(chart, stem: str, title: str) -> None:
    try:
        chart = chart.properties(title=title)
    except Exception:
        pass
    html_path = OUT / f"{stem}.html"
    try:
        chart.save(str(html_path))
        return
    except Exception:
        pass
    try:
        chart.save(str(OUT / f"{stem}.json"))
    except Exception:
        pass


def xr_to_csv(ds, path: Path) -> bool:
    try:
        df = ds.to_dataframe().reset_index()
        df.to_csv(path, index=False)
        return True
    except Exception:
        try:
            ds.to_netcdf(path.with_suffix(".nc"))
            return True
        except Exception:
            return False


def load_national_paid_media(pd, meridian_mod):
    vendored = ROOT / "data" / "national_media.csv"
    if vendored.is_file():
        return pd.read_csv(vendored)
    pkg_csv = (
        Path(meridian_mod.__file__).resolve().parent
        / "data"
        / "simulated_data"
        / "csv"
        / "national_media.csv"
    )
    if pkg_csv.is_file():
        return pd.read_csv(pkg_csv)
    return pd.read_csv(NATIONAL_MEDIA_CSV)


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)

    if sys.version_info < (3, 11):
        write_not_run_stub(
            "SAMPLE not run. Google Meridian requires Python 3.11+ "
            f"(docs: 3.11 or 3.12). This interpreter is {sys.version.split()[0]}. "
            "Create the env in environment.yml, then rerun. "
            "https://github.com/google/meridian"
        )
        print(
            "Meridian needs Python 3.11+. "
            f"Got {sys.version.split()[0]}. See environment.yml.",
            file=sys.stderr,
        )
        return 1

    try:
        import pandas as pd
        import tensorflow_probability as tfp
        from meridian import constants
        from meridian.analysis import analyzer, optimizer, summarizer, visualizer
        from meridian.data import data_frame_input_data_builder
        from meridian.model import model, prior_distribution, spec
        import meridian as meridian_mod
    except Exception as exc:
        write_not_run_stub(
            "SAMPLE not run. `import meridian` failed "
            f"({type(exc).__name__}: {exc}). "
            "Install with Python 3.11+: `conda env create -f environment.yml` "
            "or `python3.11 -m pip install --upgrade google-meridian` "
            "(https://github.com/google/meridian)."
        )
        print(
            "import meridian failed. "
            "Python 3.11+ and `pip install --upgrade google-meridian` "
            f"(macOS CPU). {type(exc).__name__}: {exc}",
            file=sys.stderr,
        )
        return 1

    try:
        df = load_national_paid_media(pd, meridian_mod)
        builder = data_frame_input_data_builder.DataFrameInputDataBuilder(
            kpi_type="non_revenue",
            default_kpi_column="conversions",
            default_revenue_per_kpi_column="revenue_per_conversion",
        )
        if hasattr(builder, "currency_code"):
            builder.currency_code = "USD"
        builder = (
            builder.with_kpi(df)
            .with_revenue_per_kpi(df)
            .with_controls(df, control_cols=CONTROL_COLS)
        )
        builder = builder.with_media(
            df,
            media_cols=[f"{ch}_impression" for ch in CHANNELS],
            media_spend_cols=[f"{ch}_spend" for ch in CHANNELS],
            media_channels=CHANNELS,
        )
        data = builder.build()

        roi_mu = 0.2
        roi_sigma = 0.9
        prior = prior_distribution.PriorDistribution(
            roi_m=tfp.distributions.LogNormal(
                roi_mu, roi_sigma, name=constants.ROI_M
            )
        )
        try:
            model_spec = spec.ModelSpec(prior=prior, enable_aks=True)
        except TypeError:
            model_spec = spec.ModelSpec(prior=prior)

        mmm = model.Meridian(input_data=data, model_spec=model_spec)
        mmm.sample_prior(N_PRIOR)
        try:
            mmm.sample_posterior(
                n_chains=N_CHAINS,
                n_adapt=N_ADAPT,
                n_burnin=N_BURNIN,
                n_keep=N_KEEP,
                seed=0,
            )
        except TypeError:
            mmm.sample_posterior(
                n_keep=N_KEEP,
                n_burnin=N_BURNIN,
                n_chains=N_CHAINS,
            )
    except Exception as exc:
        write_not_run_stub(
            "SAMPLE not run. Data load or MCMC failed "
            f"({type(exc).__name__}: {exc}). No posterior artifacts."
        )
        traceback.print_exc()
        return 1

    wrote = []
    az = analyzer.Analyzer(mmm)
    try:
        summary = az.summary_metrics(use_kpi=False)
        if xr_to_csv(summary, OUT / "posterior_contribution.csv"):
            wrote.append("posterior_contribution.csv")
    except Exception:
        try:
            summary = az.summary_metrics(use_kpi=True)
            if xr_to_csv(summary, OUT / "posterior_contribution.csv"):
                wrote.append("posterior_contribution.csv")
        except Exception:
            traceback.print_exc()

    try:
        curves = az.response_curves(use_kpi=False)
        if xr_to_csv(curves, OUT / "saturation_response_curves.csv"):
            wrote.append("saturation_response_curves.csv")
    except Exception:
        try:
            curves = az.response_curves(use_kpi=True)
            if xr_to_csv(curves, OUT / "saturation_response_curves.csv"):
                wrote.append("saturation_response_curves.csv")
        except Exception:
            traceback.print_exc()

    try:
        media_summary = visualizer.MediaSummary(mmm)
        save_altair(
            media_summary.plot_contribution_waterfall_chart(),
            "SAMPLE_meridian_contribution_waterfall",
            "SAMPLE: Meridian posterior contribution (national_media)",
        )
        save_altair(
            media_summary.plot_spend_vs_contribution(),
            "SAMPLE_meridian_spend_vs_contribution",
            "SAMPLE: Meridian spend vs contribution (national_media)",
        )
        wrote.append("SAMPLE contribution charts")
    except Exception:
        traceback.print_exc()

    try:
        media_effects = visualizer.MediaEffects(mmm)
        save_altair(
            media_effects.plot_response_curves(
                plot_separately=False, include_ci=False
            ),
            "SAMPLE_meridian_response_curves",
            "SAMPLE: Meridian response / saturation (national_media)",
        )
        save_altair(
            media_effects.plot_hill_curves(),
            "SAMPLE_meridian_hill_saturation",
            "SAMPLE: Meridian Hill saturation (national_media)",
        )
        wrote.append("SAMPLE saturation charts")
    except Exception:
        traceback.print_exc()

    try:
        mmm_summarizer = summarizer.Summarizer(mmm)
        times = list(mmm.input_data.time.values)
        mmm_summarizer.output_model_results_summary(
            "SAMPLE_summary_output.html",
            str(OUT),
            str(times[0]),
            str(times[-1]),
        )
        wrote.append("SAMPLE_summary_output.html")
    except Exception:
        traceback.print_exc()

    budget_ok = False
    try:
        budget_optimizer = optimizer.BudgetOptimizer(mmm)
        optimization_results = budget_optimizer.optimize()
        non = optimization_results.nonoptimized_data
        opt = optimization_results.optimized_data
        xr_to_csv(non, OUT / "budget_current.csv")
        xr_to_csv(opt, OUT / "budget_recommended.csv")
        try:
            df_non = non[["spend"]].to_dataframe().reset_index()
            df_opt = opt[["spend"]].to_dataframe().reset_index()
            merged = df_non.merge(
                df_opt, on="channel", suffixes=("_current", "_recommended")
            )
            merged.to_csv(OUT / "budget_reallocation.csv", index=False)
            budget_ok = True
            wrote.append("budget_reallocation.csv")
        except Exception:
            traceback.print_exc()

        try:
            import matplotlib.pyplot as plt

            if budget_ok:
                fig, ax = plt.subplots(figsize=(8, 4.5))
                x = list(range(len(merged)))
                w = 0.35
                ax.bar(
                    [i - w / 2 for i in x],
                    merged["spend_current"],
                    width=w,
                    label="current",
                )
                ax.bar(
                    [i + w / 2 for i in x],
                    merged["spend_recommended"],
                    width=w,
                    label="recommended",
                )
                ax.set_xticks(x)
                ax.set_xticklabels(list(merged["channel"]), rotation=20, ha="right")
                ax.set_title(
                    "SAMPLE: Meridian budget reallocation (national_media)"
                )
                ax.set_ylabel("spend")
                ax.legend()
                fig.tight_layout()
                fig.savefig(OUT / "SAMPLE_meridian_budget_reallocation.png", dpi=120)
                plt.close(fig)
                wrote.append("SAMPLE_meridian_budget_reallocation.png")
        except Exception:
            traceback.print_exc()

        try:
            save_altair(
                optimization_results.plot_spend_delta(),
                "SAMPLE_meridian_spend_delta",
                "SAMPLE: Meridian spend delta (national_media)",
            )
            save_altair(
                optimization_results.plot_budget_allocation(optimized=True),
                "SAMPLE_meridian_budget_allocation_recommended",
                "SAMPLE: Meridian recommended allocation (national_media)",
            )
            save_altair(
                optimization_results.plot_budget_allocation(optimized=False),
                "SAMPLE_meridian_budget_allocation_current",
                "SAMPLE: Meridian current allocation (national_media)",
            )
        except Exception:
            traceback.print_exc()

        try:
            optimization_results.output_optimization_summary(
                "SAMPLE_optimization_output.html", str(OUT)
            )
            wrote.append("SAMPLE_optimization_output.html")
        except Exception:
            traceback.print_exc()
    except Exception:
        traceback.print_exc()
        _write(
            OUT / "budget_reallocation.md",
            (
                "# SAMPLE: Meridian budget reallocation\n\n"
                "`BudgetOptimizer.optimize()` did not finish. "
                "No recommended spend is reported. Do not invent dollars.\n"
            ),
        )

    _write(
        OUT / "README.md",
        (
            "# SAMPLE: Meridian run notes\n\n"
            "Official national paid-media CSV "
            f"(`national_media.csv`). Laptop MCMC: n_chains={N_CHAINS}, "
            f"n_adapt={N_ADAPT}, n_burnin={N_BURNIN}, n_keep={N_KEEP}. "
            "Production Getting Started: n_chains=10, n_adapt=2000, "
            "n_burnin=500, n_keep=1000.\n\n"
            f"Artifacts: {', '.join(wrote) if wrote else 'none'}.\n\n"
            "Not McFly client Meridian. Not Black Clover / Nutricost ROI.\n\n"
            "Decision: [`decision.md`](decision.md).\n"
        ),
    )
    print(f"SAMPLE: Meridian artifacts in {OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
