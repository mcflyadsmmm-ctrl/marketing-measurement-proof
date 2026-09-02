# SAMPLE: Meta Robyn MMM (`dt_simulated_weekly`)

Public SAMPLE from [facebookexperimental/Robyn](https://github.com/facebookexperimental/Robyn). Not client data. Not Black Clover. Not Nutricost. Plot titles and this first line are labeled SAMPLE.

**Shared decision (required):** [Robyn vs Meridian — one budget decision](../03-meridian/out/decision.md). If Allocator and Meridian disagree on a high-spend, low-incremental channel: trust the geo test, freeze that channel’s MMM coefficient, do not average the two allocators.

R **4.6.1** is on this Mac. `Rscript R/run_robyn.R` still needs the Robyn package + Nevergrad (`CONNECTORS.md`). The script prints the official install and exits 1 if `Robyn` is missing.

## What it produces

- Data: package `dt_simulated_weekly` (demo window `2016-01-01`–`2018-12-31`).
- OnePager, response / saturation (`robyn_response` + Hill), Allocator **current vs recommended** (`scenario = "max_response"`, `date_range = "last_10"`).
- Holdout: last **10** weeks of that window. MAPE in `out/holdout_mape.txt`. Nevergrad is **timeboxed** (200 iterations × 1 trial). Production (official `demo.R`) is **2000 iterations × 5 trials**. Do not treat the laptop Pareto as a shipped model.
- Allocator dollars are written only if `robyn_allocator()` finishes. This folder will not invent them.

## Install

R ≥ 4.3, then the commands from the [official Robyn README](https://github.com/facebookexperimental/Robyn) and [Nevergrad guide](https://github.com/facebookexperimental/Robyn/blob/main/demo/install_nevergrad.R):

```r
install.packages("Robyn")
# remotes::install_github("facebookexperimental/Robyn/R")  # dev

install.packages("reticulate")
library("reticulate")
virtualenv_create("r-reticulate")
use_virtualenv("r-reticulate", required = TRUE)
Sys.setenv(RETICULATE_PYTHON = "~/.virtualenvs/r-reticulate/bin/python")
py_install("numpy", pip = TRUE)
py_install("nevergrad", pip = TRUE)
```

Official note: Python 3.10+ **may** break Nevergrad (`demo/install_nevergrad.R`).

## Run

```bash
Rscript R/run_robyn.R
```

Expected runtime on a laptop: minutes for the timeboxed Nevergrad, not four hours. If `Robyn` or `nevergrad` is missing, the script prints the install above and exits 1.
