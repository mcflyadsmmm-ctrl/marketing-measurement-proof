#!/usr/bin/env Rscript
# SAMPLE: GeoLift as the docs write it — not the collapsed-cell known-lift path.
# 1) Official walkthrough: chicago + portland on GeoTestData_Test (periods 91–105).
# 2) N=1 known-lift: milwaukee only, +8% inject on pre-test, no collapse.
# Writes out/walkthrough.md + CSVs. Does not overwrite att.csv from run_geolift.R.

options(stringsAsFactors = FALSE)
options(repos = c(CRAN = "https://cloud.r-project.org"))

root <- getwd()
file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(file_arg)) {
  script_dir <- dirname(normalizePath(sub("^--file=", "", file_arg[1])))
  root <- dirname(script_dir)
  setwd(root)
}
source(file.path(root, "R", "inject_lift.R"), local = FALSE)
out_dir <- file.path(root, "out")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

suppressPackageStartupMessages({
  library(GeoLift)
})

write_fail <- function(path, title, err) {
  writeLines(
    c(
      title,
      "",
      "SAMPLE. Not client data. Not Black Clover.",
      "",
      paste0("**Result:** GeoLift() threw: `", conditionMessage(err), "`"),
      "",
      "This is the augsynth 0.2.0 `treated_table()` N>1 failure the collapsed-cell",
      "path in `R/run_geolift.R` exists to survive. Official walkthrough uses",
      "`locations = c(\"chicago\", \"portland\")` on the test panel",
      "(https://github.com/facebookincubator/GeoLift/blob/main/vignettes/GeoLift_Walkthrough.md).",
      "",
      "Do not invent ATT dollars for this path."
    ),
    path
  )
}

capture_fit <- function(fit) {
  list(
    att = tryCatch(as.numeric(fit$inference$ATT[1]), error = function(e) NA_real_),
    pct = tryCatch(as.numeric(fit$inference$Perc.Lift[1]), error = function(e) NA_real_),
    pvalue = tryCatch(as.numeric(fit$inference$pvalue[1]), error = function(e) NA_real_),
    incremental = tryCatch(as.numeric(fit$incremental[1]), error = function(e) NA_real_)
  )
}

# --- Official walkthrough panel ---
data("GeoLift_PreTest", package = "GeoLift")
data("GeoLift_Test", package = "GeoLift")
GeoTestData_Test <- GeoDataRead(
  data = GeoLift_Test,
  date_id = "date",
  location_id = "location",
  Y_id = "Y",
  X = c(),
  format = "yyyy-mm-dd",
  summary = FALSE
)
GeoTestData_PreTest <- GeoDataRead(
  data = GeoLift_PreTest,
  date_id = "date",
  location_id = "location",
  Y_id = "Y",
  X = c(),
  format = "yyyy-mm-dd",
  summary = FALSE
)

message("=== 1) Official chicago + portland on GeoTestData_Test ===")
walk_ok <- FALSE
walk_fit <- tryCatch(
  GeoLift(
    Y_id = "Y",
    data = GeoTestData_Test,
    locations = c("chicago", "portland"),
    treatment_start_time = 91,
    treatment_end_time = 105,
    ConfidenceIntervals = TRUE,
    alpha = 0.05
  ),
  error = function(e) e
)
if (inherits(walk_fit, "error")) {
  write_fail(
    file.path(out_dir, "walkthrough.md"),
    "# SAMPLE: official GeoLift walkthrough (chicago + portland)",
    walk_fit
  )
  message("Walkthrough FAILED: ", conditionMessage(walk_fit))
} else {
  walk_ok <- TRUE
  inf <- capture_fit(walk_fit)
  utils::write.csv(
    data.frame(
      path = "official_walkthrough",
      locations = "chicago, portland",
      treatment_start = 91,
      treatment_end = 105,
      att = inf$att,
      percent_lift = inf$pct,
      pvalue = inf$pvalue,
      incremental = inf$incremental,
      known_inject = NA,
      collapsed = FALSE,
      stringsAsFactors = FALSE
    ),
    file.path(out_dir, "walkthrough_att.csv"),
    row.names = FALSE
  )
  writeLines(
    c(
      "# SAMPLE: official GeoLift walkthrough (chicago + portland)",
      "",
      "SAMPLE. Not client data. Not Black Clover. This is Meta’s documented",
      "`GeoLift()` call on `GeoTestData_Test`, periods 91–105, two treated cities.",
      "Ground truth is **not** a known +8% we injected. It is the vignette campaign.",
      "",
      sprintf("- ATT = %s", signif(inf$att, 4)),
      sprintf("- Percent lift = %s", signif(inf$pct, 4)),
      sprintf("- p = %s", signif(inf$pvalue, 3)),
      "",
      "N=2 treated units **ran** on this augsynth pin. The known-lift path still",
      "collapses N=3 because that panel + conformal summary still dies — see",
      "`out/CMO-brief.md`."
    ),
    file.path(out_dir, "walkthrough.md")
  )
  message("Walkthrough OK att=", inf$att, " pct=", inf$pct)
}

message("=== 2) N=1 milwaukee +8% inject, no collapse ===")
max_t <- max(GeoTestData_PreTest$time)
inject_end <- max_t
inject_start <- max_t - 4L + 1L
injected <- inject_relative_lift(
  data = GeoTestData_PreTest,
  locations = "milwaukee",
  treatment_start_time = inject_start,
  treatment_end_time = inject_end,
  lift = 0.08
)
n1_fit <- tryCatch(
  GeoLift(
    Y_id = "Y",
    data = injected,
    locations = "milwaukee",
    treatment_start_time = inject_start,
    treatment_end_time = inject_end,
    alpha = 0.1,
    model = "none",
    fixed_effects = TRUE,
    ConfidenceIntervals = TRUE,
    method = "conformal",
    grid_size = 150,
    stat_test = "Total",
    conformal_type = "iid",
    ns = 1000
  ),
  error = function(e) e
)
if (inherits(n1_fit, "error")) {
  writeLines(
    c(
      "# SAMPLE: N=1 GeoLift (milwaukee, +8% inject, no collapse)",
      "",
      paste0("**Result:** threw: `", conditionMessage(n1_fit), "`"),
      "",
      "Do not invent ATT. Collapsed N=3 path remains in att.csv."
    ),
    file.path(out_dir, "n1.md")
  )
  message("N=1 FAILED: ", conditionMessage(n1_fit))
} else {
  inf1 <- capture_fit(n1_fit)
  utils::write.csv(
    data.frame(
      path = "n1_milwaukee_inject",
      locations = "milwaukee",
      treatment_start = inject_start,
      treatment_end = inject_end,
      att = inf1$att,
      percent_lift = inf1$pct,
      pvalue = inf1$pvalue,
      incremental = inf1$incremental,
      known_inject = 0.08,
      collapsed = FALSE,
      stringsAsFactors = FALSE
    ),
    file.path(out_dir, "n1_att.csv"),
    row.names = FALSE
  )
  writeLines(
    c(
      "# SAMPLE: N=1 GeoLift (milwaukee, +8% inject, no collapse)",
      "",
      "SAMPLE. Not client data. One treated city so augsynth `treated_table()` is not asked to transpose N>1.",
      "Known inject +8% on cash sales (Y). This is the library as written for N=1.",
      "The Recast interview ATT remains the collapsed three-city cell in `att.csv`.",
      "",
      sprintf("- ATT = %s", signif(inf1$att, 4)),
      sprintf("- Percent lift = %s%%", signif(inf1$pct, 4)),
      sprintf("- p = %s", signif(inf1$pvalue, 3)),
      sprintf("- Window periods %s–%s", inject_start, inject_end)
    ),
    file.path(out_dir, "n1.md")
  )
  message("N=1 OK att=", inf1$att, " pct=", inf1$pct)
}

writeLines(
  c(
    paste0("walkthrough_ok=", walk_ok),
    paste0("n1_ok=", !inherits(n1_fit, "error")),
    paste0("timestamp=", format(Sys.time(), tz = "America/Denver"))
  ),
  file.path(out_dir, "documented_paths.txt")
)
message("Wrote documented-path artifacts in ", out_dir)
