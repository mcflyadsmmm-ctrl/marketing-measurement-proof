SAMPLE: Hightouch EDA take-home muscle

Public SAMPLE. **Not** a Hightouch customer extract. **Not** Black Clover. **Not** Nutricost.

Muscle for the [Forward Deployed Marketing Data Scientist](https://job-boards.greenhouse.io/hightouch/jobs/5718912004) loop: Polars/Pandas EDA in Jupyter, warehouse SQL, incrementality / counterfactuals / cohorts, send-volume and reachability, then a 90-minute experiment design. ~30% of the seat is customer-facing — last artifact is a marketer paragraph, not SHAP.

No PyTorch. No reward-function agent. No Zip ML theater.

## Run (Python 3.9.6)

From this folder, using the repo venv (polars, duckdb, pandas, matplotlib):

```bash
../.venv/bin/python generate_sends.py && ../.venv/bin/python analysis.py
```

Notebook (same narrative; last cell prints the marketer paragraph):

```bash
../.venv/bin/jupyter notebook analysis.ipynb
```

DuckDB SQL that reproduces incremental CR on the clean file:

```bash
../.venv/bin/python -c "import duckdb; print(duckdb.sql(open('sql/incremental_cr.sql').read()))"
```

Runtime: under 30 seconds on this laptop.

## What the files are

| File | Role |
|---|---|
| `generate_sends.py` | Seed **2020**. Writes `data/sends.csv` and `data/sends_contaminated.csv`. |
| `analysis.py` | Polars load + `group_by`. Wilson CR + bootstrap incremental CR. Clean vs contaminated. |
| `sql/incremental_cr.sql` | DuckDB ITT incremental CR on the clean CSV. |
| `analysis.ipynb` | Live-review walkthrough. Last cell = marketer paragraph. |
| `out/clean_lift.csv` / `out/contaminated_lift.csv` | Headline numbers. |
| `out/marketer.md` | Would not ship; holdout is contaminated; kill rule. |
| `out/experiment_design.md` | One page for the 90-minute screen. |

Columns: `user_id`, `cohort_week`, `channel`, `sent`, `converted`, `revenue`, `holdout_flag`. `converted` / `revenue` are **4-week** post-cohort outcomes.

## SAMPLE DGP (documented here; not “the estimate”)

- 12,000 users, 8 Monday cohorts from `2024-01-01`, 1,500 per week, channel = email.
- **40%** exact user holdout (`holdout_flag=1`). Clean file: those users have `sent=0`.
- 12% unreachable. Weekly **send cap 700** among treated-and-reachable (volume + reachability, not 100% of treated).
- Baseline 4-week CR is ~4%, except promo week `2024-01-01` at 7%. Lift **if actually sent**: +9pp that week, ~+1.5–2.0pp otherwise. Most incremental cash is in one cohort on purpose.
- Contaminated copy: **15%** of holdout users receive the email (`sent=1`) and take the treated potential outcome. `holdout_flag` stays 1.

## Live-review point

Read ITT (`holdout_flag`), not sent vs unsent. On the clean file the send is incremental. On the contaminated file the holdout is not a holdout — holdout CR rises, incremental CR collapses. Kill rule: if send rate among `holdout_flag=1` is above 1%, stop. Do not scale. Do not retune an agent on a dirty counterfactual.

## SAMPLE headline numbers (seed 2020)

| | Clean holdout | Contaminated (15% of holdout actually sent) |
|---|---|---|
| Treated / holdout n | 7,200 / 4,800 | same assignment |
| Treated sent-rate | 77.8% (cap + reachability) | 77.8% |
| Holdout sent-rate | **0%** | **15%** — kill |
| Treated CR | 6.38% | 6.38% |
| Holdout CR | 4.29% | 4.65% |
| Incremental CR (bootstrap 95% CI) | **2.08%** (1.28% to 2.88%) | **1.73%** (0.90% to 2.56%) |

DuckDB SQL matches Polars on the clean file: incremental CR = 0.020833. Promo week `2024-01-01` carries most incremental cash per user (~+$4.34 vs ~+$0.29 to +$1.61 on later weeks).
