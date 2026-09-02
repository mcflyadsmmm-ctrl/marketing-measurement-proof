# SAMPLE: marketing-measurement-proof

Public SAMPLE work for Marty Smithson’s measurement hunt. **Not** Black Clover. **Not** Nutricost. **Not** client data.

Spec: `../../04 Job targets/PROOF-PROJECTS.md`  
Connectors: [`CONNECTORS.md`](CONNECTORS.md)

If Recast screens this week, stop after `01-geolift` and apply.

| Folder | Must run | Unlocks |
|---|---|---|
| `00-recast-r-memo` | `Rscript R/run.R` | Recast take-home |
| `01-geolift` | `Rscript R/run_geolift.R` | Every science screen + Haus POV |
| `02-robyn` + `03-meridian` | Robyn Allocator vs Meridian budget; `out/decision.md` picks a side | Mozilla, Lovevery |
| `04-mer-warehouse` | `dbt build` or `python run_build.py` | Lola, Hightouch SQL |
| `05-hightouch-eda` | Polars holdout, then a contaminated holdout that blows the lift | Hightouch take-home |
| `06-lola-pulse` | Pulse table + VoC codebook + BFCM note | Lola |
| `07-causalimpact` | Pre/post declared; failure if you move the date | Mozilla |
| `08-test-calendar` | 90-day calendar + 11:00 MER cut | Lovevery |

Python 3.9 venv:

```bash
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
```

R is **not** optional for Recast. Install the CRAN arm64 pkg first (`CONNECTORS.md`).
