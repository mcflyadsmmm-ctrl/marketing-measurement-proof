# SAMPLE: official GeoLift walkthrough (chicago + portland)

SAMPLE. Not client data. Not Black Clover.

**Result:** GeoLift() threw: `Tibble columns must have compatible sizes.
• Size 105: Existing data.
• Size 210: Column `Yobs`.
ℹ Only values of size one are recycled.`

This is the augsynth 0.2.0 `treated_table()` N>1 failure the collapsed-cell
path in `R/run_geolift.R` exists to survive. Official walkthrough uses
`locations = c("chicago", "portland")` on the test panel
(https://github.com/facebookincubator/GeoLift/blob/main/vignettes/GeoLift_Walkthrough.md).

Do not invent ATT dollars for this path.
