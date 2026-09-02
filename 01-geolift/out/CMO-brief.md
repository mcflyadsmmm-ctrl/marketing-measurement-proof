SAMPLE: CMO brief — scale / cut / rerun

Not client data. Not Black Clover. facebookincubator/GeoLift vignette panel. KPI language is **cash sales** even though the package column is `Y`.

`Rscript R/run_geolift.R` overwrites this file with ATT, CI, and p from the +8% inject. Until R exists on this Mac, numbers below are the decision rule, not a recovered lift.

## One geo test (interview)

- **Markets:** treatment cities from `GeoLiftMarketSelection()` on `GeoTestData_PreTest` (40 US cities shipped in the package). Names come from that object after R runs — see `out/markets.csv`. This SAMPLE does not invent DMAs.
- **KPI:** cash sales (package `Y`).
- **Design target:** 5% MDE at about 80% power, small grid (`N = 2,3`, four treatment periods first). If four periods cannot see 5% at 80%, the script says so and writes the implied duration / unit budget from the ranking table.
- **Result protocol:** copy the series, inject **+8%** in treatment for a **4-period** window, fit `GeoLift()`. Read ATT, 90% CI, p from `out/att.csv`.
- **If the CI misses 8%:** say so. That is the point of a known-lift SAMPLE. Do not round it to a story.

## What I would cut

- A market that is ~40% of cash sales — synthetic control then copies the treated series. The script skips that rank when `ProportionTotal_Y > 0.40`.
- Overlapping media: treatment geos that still see the tactic (national social, commuting spillover). SAMPLE data cannot show the buy; I would refuse it on a live desk.
- National TV and always-on brand I will not actually pause. GeoLift does not identify them. See `out/identification.md`.
- “Meta all-up” if the MMM splits ASC vs prospecting. See `out/mmm-first-vs-geolift-first.md`.

## Scale / cut / rerun

- **Scale** only if p is under the 0.10 GeoLift default **and** the incremental CI is above zero **and** cash MER on the implied incremental still clears. An ATT that recovers +8% inside the CI is evidence to scale that **geo-assignable cell**, not a license to raise every platform.
- **Cut** if p is weak, the CI includes zero, or the recovered lift is not worth the holdout. Do not scale platform ROAS that disagrees with this ATT.
- **Rerun** if the design never had 80% power at 5% MDE, or if the CI misses the injected 8%. Lengthen the window or add spend. Do not stuff a four-day noisy ATT into an MMM as “validation.”

Haus vs Recast sequencing lives in `out/mmm-first-vs-geolift-first.md`. Short version: experiment results **anchor** the response curve. Recast “validate the model” is the opposite order.
