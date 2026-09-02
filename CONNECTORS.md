# Connectors — what is on this Mac (1 Sep 2026, evening)

Nothing here needs Shopify, ads accounts, or Black Clover. Public SAMPLE only.

## Landed tonight

| Stack | What | Where |
|---|---|---|
| **R 4.6.1** arm64 | Recast OLS memo already ran | `/usr/local/bin/Rscript` |
| **GeoLift 2.7.5** + augsynth 0.2.0 | Recast / Haus geo | R library. `augsynth` is GitHub-only (not CRAN). |
| **Robyn 3.12.1** + Nevergrad 1.0.12 | Mozilla / Lovevery MMM | R + `~/.virtualenvs/r-reticulate` on **Apple Python 3.9.6** |
| **google-meridian 1.8.0** | Mozilla / Lovevery MMM | `03-meridian/.venv` on **python.org 3.11.9** |
| **CausalImpact 1.4.1** | Mozilla named library | Came in with GeoLift deps |
| **GitHub** | Public SAMPLE | [`mcflyadsmmm-ctrl/marketing-measurement-proof`](https://github.com/mcflyadsmmm-ctrl/marketing-measurement-proof) via `gh` |

## Two Pythons — do not mix

[Robyn’s Nevergrad guide](https://github.com/facebookexperimental/Robyn/blob/main/demo/install_nevergrad.R) warns **Python 3.10+ may break Nevergrad**. [Google’s Meridian install](https://developers.google.com/meridian/docs/user-guide/installing) requires **3.11 or 3.12**.

| Binary | Version | Use for |
|---|---|---|
| `/usr/bin/python3` | Apple **3.9.6** | Robyn Nevergrad only (`r-reticulate`) |
| `/usr/local/bin/python3.11` | python.org **3.11.9** | Meridian venv only |
| `python3` on PATH after tonight | likely **3.11.9** | Do not recreate the warehouse `.venv` with this |

Warehouse / Hightouch / Lola stay on the repo `.venv` (created under 3.9). Leave it.

## Run (after install)

```bash
cd "08 Proof/marketing-measurement-proof"

# Recast-week — do this first. Target < 20 min.
cd 01-geolift && Rscript R/run_geolift.R

# Robyn (timeboxed Nevergrad). Force 3.9.
export RETICULATE_PYTHON="$HOME/.virtualenvs/r-reticulate/bin/python"
cd ../02-robyn && Rscript R/run_robyn.R

# Meridian (timeboxed MCMC). Force 3.11 venv. Vendored CSV (SSL blocked GitHub raw).
cd ../03-meridian && .venv/bin/python python/run_meridian.py
```

GeoLift ATT, Robyn Allocator, and Meridian posterior **have run** on this machine (1 Sep 2026). If Recast books a screen, **stop after GeoLift and apply**. Robyn/Meridian are not a reason to sit on Greenhouse.

## Re-install (only if a machine is wiped)

**GeoLift** — `augsynth` is not on CRAN:

```r
install.packages("remotes", repos = "https://cloud.r-project.org")
remotes::install_github("ebenmichael/augsynth")
remotes::install_github("facebookincubator/GeoLift")
```

**Robyn** — CRAN binary + Nevergrad on 3.9:

```bash
/usr/bin/python3 -m venv ~/.virtualenvs/r-reticulate
~/.virtualenvs/r-reticulate/bin/pip install "numpy==1.26.4" nevergrad
```

```r
install.packages("Robyn")
```

**Meridian** — python.org 3.11 pkg, then:

```bash
/usr/local/bin/python3.11 -m venv 03-meridian/.venv
03-meridian/.venv/bin/pip install "google-meridian>=1.7.0,<2"
```

Python 3.11 pkg (already in Downloads if you need it again): [python-3.11.9-macos11.pkg](https://www.python.org/ftp/python/3.11.9/python-3.11.9-macos11.pkg)

## Later (Lola pulse only)

Tableau Public or Looker trial — screenshot labeled Looker/Tableau, not Studio. Pulse CSV already exists without it.

## Never connect

Shopify, Klaviyo, Meta/Google/Amazon/TikTok ads, Snowflake, NetSuite, Black Clover, Nutricost, Recast/Haus/Meridian customer tenants, any live revenue file.
