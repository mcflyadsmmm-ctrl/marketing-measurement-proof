#!/usr/bin/env Rscript
# SAMPLE national CausalImpact (Brodersen et al.).
# Not Black Clover. Not client data. Pre/post declared BEFORE fit.
#
# Named library: CausalImpact. Python python/failure_case.py is a transparent
# pre-period regression and is NOT this package.
#
# Run from 07-causalimpact/:  Rscript R/run_causalimpact.R
# Requires: CausalImpact (and zoo, which it imports).

this_dir <- (function() {
  args <- commandArgs(trailingOnly = FALSE)
  hit <- grep("^--file=", args, value = TRUE)
  if (length(hit) == 1) {
    return(dirname(normalizePath(sub("^--file=", "", hit))))
  }
  getwd()
})()
root <- normalizePath(file.path(this_dir, ".."))
out_dir <- file.path(root, "out")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

if (!requireNamespace("CausalImpact", quietly = TRUE)) {
  stop(
    "CausalImpact is not installed. R is the named Brodersen library; ",
    "tonight's runnable path is python/failure_case.py (not Brodersen)."
  )
}

library(CausalImpact)

TRUE_INTERVENTION_WEEK <- 80L
WRONG_INTERVENTION_WEEK <- 60L
N_WEEKS <- 104L
TRUE_LIFT <- 0.12

# Locked before fit (good design).
good_pre <- c(1L, TRUE_INTERVENTION_WEEK - 1L)
good_post <- c(TRUE_INTERVENTION_WEEK, N_WEEKS)
# Failure: move the date. Would not ship.
bad_pre <- c(1L, WRONG_INTERVENTION_WEEK - 1L)
bad_post <- c(WRONG_INTERVENTION_WEEK, N_WEEKS)

csv_path <- file.path(out_dir, "national_weekly_sample.csv")
if (file.exists(csv_path)) {
  dat <- read.csv(csv_path, stringsAsFactors = FALSE)
  message("Loaded ", csv_path, " (same SAMPLE series as Python).")
} else {
  message("CSV missing; generating a SAMPLE series in R (will not match numpy RNG).")
  set.seed(20260901)
  week <- seq_len(N_WEEKS)
  seasonal <- sin(2 * pi * week / 52)
  seasonal_c <- cos(2 * pi * week / 52)
  x_search <- 100 + 0.15 * week + 8 * seasonal + rnorm(N_WEEKS, 0, 2)
  x_category <- 80 + 0.08 * week + 5 * seasonal_c + rnorm(N_WEEKS, 0, 1.5)
  base <- 50000 + 45 * x_search + 30 * x_category + rnorm(N_WEEKS, 0, 280)
  treated <- as.integer(week >= TRUE_INTERVENTION_WEEK)
  y <- base * (1 + TRUE_LIFT * treated)
  dat <- data.frame(
    week = week,
    y_cash = y,
    x_search_index = x_search,
    x_category_demand = x_category
  )
  write.csv(dat, csv_path, row.names = FALSE)
}

series <- cbind(
  y_cash = dat$y_cash,
  x_search_index = dat$x_search_index,
  x_category_demand = dat$x_category_demand
)

run_one <- function(pre, post, png_name, md_name, ship) {
  impact <- CausalImpact(series, pre.period = pre, post.period = post)
  png(file.path(out_dir, png_name), width = 1100, height = 900)
  p <- plot(impact)
  if (inherits(p, "ggplot") && requireNamespace("ggplot2", quietly = TRUE)) {
    print(p + ggplot2::ggtitle(paste0("SAMPLE: CausalImpact (Brodersen) — ", md_name)))
  } else {
    plot(impact)
    title(main = paste0("SAMPLE: CausalImpact — ", md_name), outer = TRUE)
  }
  dev.off()

  sm <- impact$summary
  md <- file.path(out_dir, md_name)
  con <- file(md, open = "wt")
  on.exit(close(con), add = TRUE)
  writeLines("SAMPLE. Brodersen CausalImpact. Not Python.", con)
  writeLines("", con)
  writeLines(sprintf("Pre-period weeks %s–%s. Post-period weeks %s–%s.", pre[1], pre[2], post[1], post[2]), con)
  writeLines(sprintf("True DGP: +%.0f%% from week %s.", 100 * TRUE_LIFT, TRUE_INTERVENTION_WEEK), con)
  writeLines(sprintf("Ship this design? %s", if (ship) "yes, if the date was locked before fit." else "NO."), con)
  writeLines("", con)
  writeLines("Average and cumulative effects from CausalImpact$summary:", con)
  capture.output(print(sm), file = con, append = TRUE)
  writeLines("", con)
  if (!ship) {
    writeLines(
      paste(
        "Would not ship: moving the intervention date still draws a gap",
        "because the real week-80 shock sits inside the mis-dated post window.",
        "Lock the week before anyone fits. Cherry-picking the date is not identification."
      ),
      con
    )
  }
  invisible(impact)
}

run_one(
  good_pre, good_post,
  "SAMPLE_r_causalimpact_good.png",
  "r_good_design.md",
  TRUE
)
run_one(
  bad_pre, bad_post,
  "SAMPLE_r_causalimpact_failure.png",
  "r_failure_moved_date.md",
  FALSE
)

message("Wrote R CausalImpact SAMPLE outputs in ", out_dir)
