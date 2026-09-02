# SAMPLE: Robyn Allocator — current vs recommended

select_model: `1_174_1`.
Laptop Nevergrad: 200 x 1. Do not treat this mix as production.
Scenario: `max_response` on `date_range = "last_10"` of the **train** window (official demo.R).

Decision: [`../../03-meridian/out/decision.md`](../../03-meridian/out/decision.md)

Wrote `allocator_current_vs_recommended.csv` from `AllocatorCollect$dt_optimOut` (library output, not invented).

Columns present:
channels, initSpendUnit, optmSpendUnit
