SAMPLE: CMO brief — scale / cut / rerun

Not client data. Not Black Clover. facebookincubator/GeoLift 2.7.5 vignette panel. KPI is **cash sales** (package column Y). Runtime 0.22 minutes.

## One geo test (interview)

- **Markets (treatment):** milwaukee, orlando, saint paul
- **Control:** 37 remaining complete cities in GeoTestData_PreTest (Honolulu held in the control pool, not treatment — package walkthrough).
- **KPI:** cash sales.
- **Window:** periods 87–90 (4 periods) on a copy of the pre-test series.
- **Injected truth:** +8%.
- **Result:** ATT = 1191.761; percent lift = 9.8%; incremental cash sales = 4767; p = 0.034; 90% CI (incremental) = (881.9, 9061.2).
- **CI covers 8%?** yes. 90% CI covers the injected +8%. Recovered range is wide or tight depending on power — still read p and cash MER before scaling.
- **API:** GeoLiftMarketSelection.
- **Fit note:** The treatment cities were **summed into one cell** before `GeoLift()`. augsynth 0.2.0 `treated_table()` errors when more than one treated unit is passed (`Yobs` length n_treated × T). The markets above are still the cell. Charlie can reproduce the crash with N>1 and this workaround.

## Design vs 5% MDE

Rank-1 (after 40% sales filter) can detect a 5% MDE at power 1.00 in 4 periods.

Pre-period fit: scaled L2 imbalance 0.353; test vs rest-of-panel correlation 0.975; treatment share of cash sales 6.2%.

## What I would cut

- A market that is ~40% of cash sales. This rank is under that cap.
- Overlapping media: treatment geos that still see the tactic. SAMPLE data cannot show the buy; I would refuse it on a live desk.
- National TV and always-on brand I will not pause. GeoLift does not identify them.
- Meta all-up if the MMM splits ASC vs prospecting. An all-up ATT cannot anchor either curve.

## Scale / cut / rerun

SCALE the geo-assignable cell if cash MER on the incremental still clears. Do not raise every platform off this ATT.

Haus vs Recast: experiment results **anchor** the response curve. Recast “validate the model” is the opposite order. See `out/mmm-first-vs-geolift-first.md`.

