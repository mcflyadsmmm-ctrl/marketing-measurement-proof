# SAMPLE: Google Meridian MMM (national paid-media)

Public SAMPLE from [google/meridian](https://github.com/google/meridian). Official national paid-media file: `meridian/data/simulated_data/csv/national_media.csv`. Not McFly client data. Not Black Clover. Not Nutricost. Plot titles and this first line are labeled SAMPLE.

**Python 3.11+ is required.** Google’s install docs: Python 3.11 or 3.12 ([Install Meridian](https://developers.google.com/meridian/docs/user-guide/installing)). The GitHub README lists 3.11–3.13. PyPI `google-meridian` 1.8.0 metadata says `requires_python >=3.10`; we follow **Google’s 3.11+** line, not the looser wheel tag. This Mac’s system interpreter is **3.9.6** — Meridian (and its NumPy 2 / JAX / TensorFlow stack) will not install there. `python/run_meridian.py` still implements the [Getting Started](https://developers.google.com/meridian/notebook/meridian-getting-started) / [load national-level data](https://developers.google.com/meridian/docs/user-guide/load-national-data) API and exits clearly if `import meridian` fails.

**Shared decision:** [`out/decision.md`](out/decision.md) — same memo linked from `02-robyn/README.md`.

## Install

```bash
conda env create -f environment.yml && conda activate meridian-sample
```

Equivalent (official macOS CPU, Python 3.11+):

```bash
python3.11 -m pip install --upgrade google-meridian
```

No official GPU extra on macOS (`environment.yml` is CPU).

## Run

This machine uses `03-meridian/.venv` (python.org 3.11.9) and the **vendored** `data/national_media.csv` (python.org SSL cannot fetch GitHub raw). Do not recreate this venv with Apple 3.9.

```bash
.venv/bin/python python/run_meridian.py
```

**This SAMPLE has run** (1 Sep 2026): `out/budget_reallocation.csv`, `out/posterior_contribution.csv`, `SAMPLE_meridian_budget_reallocation.png`. If the package is missing or Python is older than 3.11, the process exits 1 and leaves `out/README.md` as **SAMPLE not run**. It will not write fake budget-optimizer dollars.

Laptop MCMC is timeboxed (`n_chains=2`, `n_adapt=200`, `n_burnin=100`, `n_keep=100`). Production (Getting Started colab) is `n_chains=10`, `n_adapt=2000`, `n_burnin=500`, `n_keep=1000` on GPU. Do not ship the laptop posterior.
