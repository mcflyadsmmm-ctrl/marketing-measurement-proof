# SAMPLE: marketing-measurement-proof

Public SAMPLE for Marty Smithson. **Not** Black Clover. **Not** Nutricost. **Not** client data. Every chart title says SAMPLE.

Clone and run. Do not treat this as a W-2 extract.

## Recast first

If you are Charlie / Jeff / Thomas: read **`00-recast-r-memo`** then **`01-geolift`**. Stop there.

```bash
# R ≥ 4.3 (this SAMPLE was run on 4.6.1)
cd 00-recast-r-memo && Rscript R/run.R          # OLS + adstock CMO memo; seconds after packages
cd ../01-geolift && Rscript R/run_geolift.R     # GeoLift 2.7.5; target < 20 min
```

**00 has run.** Outputs: `out/CMO-memo.md`, `priors.md`, `experiment.md`.

**01 has run.** Milwaukee / Orlando / Saint Paul. Injected +8% cash sales. Recovered **+9.8%**, ATT 1192, p=0.034. 90% CI covers 8% and is wide. Three cities were summed into one cell because augsynth 0.2.0 crashes on N>1.

## Status on the machine that published this (1 Sep 2026)

| Folder | Ran? | What you should open |
|---|---|---|
| `00-recast-r-memo` | **Yes** — `Rscript` | CMO memo: claimed conversions 1.41× cash orders; Amazon widest CI |
| `01-geolift` | **Yes** — GeoLift 2.7.5, collapsed treatment cell | `out/att.csv`, `CMO-brief.md`, SAMPLE PNGs. augsynth 0.2.0 cannot fit N>1 treated units without summing the cell. |
| `02-robyn` | **Yes** — timeboxed Nevergrad 200×1 | Allocator CSV + OnePager. Holdout MAPE **13.06%**. Cuts OOH 30%; scales Facebook/print to the 1.5× cap. Laptop mix, not production. |
| `03-meridian` | google-meridian 1.8.0; MCMC in flight on vendored CSV | Different SAMPLE world than Robyn. Geo still wins if they disagree. |
| `04-mer-warehouse` | **Yes** — DuckDB / dbt | Cash MER = net_cash / spend; stacked claimed 1.94× |
| `05-hightouch-eda` | **Yes** — Polars | Clean incremental CR 2.08%; contaminated holdout 1.73% |
| `06-lola-pulse` | **Yes** — table + PNG | Keyword VoC; not a Looker workbook |
| `07-causalimpact` | **Yes** — Python OLS **and** R Brodersen | R: 11.2% vs known +12%, p=0.001, date locked. Moved date still fakes lift. |
| `08-test-calendar` | **Yes** | 90-day plan; 11:00 MER cut |

Python warehouse / EDA:

```bash
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
```

Meridian uses **`03-meridian/.venv`** (Python 3.11+). Robyn Nevergrad uses **Python 3.9** (`~/.virtualenvs/r-reticulate`). Do not mix them. See `CONNECTORS.md`.

## What this is not

- Not Recast’s ~30k-parameter product
- Not a Black Clover or Nutricost lift
- Not a reason to delay a Recast application
