#!/usr/bin/env Rscript
# SAMPLE: GeoLift known-lift recovery. Not client data. Not Black Clover.
# API: facebookincubator/GeoLift v2.7.5 (Jan 2026)
#   GeoLiftMarketSelection()  — power + ranking (not GeoLiftPowerFinder)
#   GeoLiftPower()            — curve for chosen markets
#   GeoLift()                 — fit
# Runtime target: < 20 min (small N, one lookback, four treatment periods).

options(stringsAsFactors = FALSE)
options(repos = c(CRAN = "https://cloud.r-project.org"))

inject_path <- NULL
root <- getwd()
file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(file_arg)) {
  script_dir <- dirname(normalizePath(sub("^--file=", "", file_arg[1])))
  root <- dirname(script_dir)
  setwd(root)
  inject_path <- file.path(script_dir, "inject_lift.R")
} else {
  cand <- c(
    file.path("R", "inject_lift.R"),
    file.path(root, "R", "inject_lift.R")
  )
  inject_path <- cand[file.exists(cand)][1]
}
if (is.na(inject_path) || !file.exists(inject_path)) {
  stop("Cannot find R/inject_lift.R from ", root)
}
source(inject_path, local = FALSE)

out_dir <- file.path(root, "out")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
t0_wall <- Sys.time()

invoke <- function(fn, args) {
  fmls <- names(formals(fn))
  if (is.null(fmls) || "..." %in% fmls) {
    return(do.call(fn, args))
  }
  keep <- intersect(names(args), fmls)
  dropped <- setdiff(names(args), fmls)
  if (length(dropped)) {
    message("Dropping unknown args for API drift: ", paste(dropped, collapse = ", "))
  }
  do.call(fn, args[keep])
}

ensure_pkg <- function(pkg, github = NULL) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    return(invisible(TRUE))
  }
  message("Installing missing package: ", pkg)
  if (identical(pkg, "augsynth")) {
    tryCatch(
      install.packages("augsynth"),
      error = function(e) {
        if (requireNamespace("remotes", quietly = TRUE)) {
          remotes::install_github("ebenmichael/augsynth")
        } else {
          stop(e)
        }
      }
    )
  } else if (!is.null(github)) {
    if (!requireNamespace("remotes", quietly = TRUE)) {
      install.packages("remotes")
    }
    remotes::install_github(github)
  } else {
    install.packages(pkg)
  }
  requireNamespace(pkg, quietly = TRUE) || stop("Failed to install ", pkg)
  invisible(TRUE)
}

ensure_pkg("remotes")
ensure_pkg("ggplot2")
ensure_pkg("augsynth")
ensure_pkg("GeoLift", github = "facebookincubator/GeoLift")

suppressPackageStartupMessages({
  library(GeoLift)
  library(ggplot2)
})

geolift_ver <- tryCatch(as.character(utils::packageVersion("GeoLift")), error = function(e) "unknown")
message("GeoLift version: ", geolift_ver)

# --- Vignette data: GeoDataRead produces GeoTestData_* (not shipped as .rda) ---
data("GeoLift_PreTest", package = "GeoLift")
data("GeoLift_Test", package = "GeoLift")

GeoTestData_PreTest <- GeoDataRead(
  data = GeoLift_PreTest,
  date_id = "date",
  location_id = "location",
  Y_id = "Y",
  X = c(),
  format = "yyyy-mm-dd",
  summary = TRUE
)
GeoTestData_Test <- GeoDataRead(
  data = GeoLift_Test,
  date_id = "date",
  location_id = "location",
  Y_id = "Y",
  X = c(),
  format = "yyyy-mm-dd",
  summary = TRUE
)

pre_locs <- sort(unique(tolower(GeoTestData_PreTest$location)))
test_locs <- sort(unique(tolower(GeoTestData_Test$location)))
if (!identical(pre_locs, test_locs)) {
  warning("PreTest and Test location sets differ; treatment names come from PreTest only.")
}
message(
  "Panel: ", length(pre_locs), " locations, ",
  max(GeoTestData_PreTest$time), " pre-test periods, ",
  max(GeoTestData_Test$time), " test-file periods (vignette campaign NOT scored)."
)

# --- Market selection: 5% MDE @ ~80% power, small grid ---
has_ms <- exists("GeoLiftMarketSelection", mode = "function")
api_note <- "GeoLiftMarketSelection"
if (!has_ms) {
  api_note <- "FALLBACK: GeoLiftMarketSelection missing; GeoLiftPowerFinder (superseded)"
  message(api_note)
}

ms_args <- function(data, treatment_periods, parallel) {
  list(
    data = data,
    treatment_periods = treatment_periods,
    N = c(2, 3),
    Y_id = "Y",
    location_id = "location",
    time_id = "time",
    effect_size = c(0, 0.05, 0.08, 0.15, 0.25),
    lookback_window = 1,
    exclude_markets = c("honolulu"),
    cpic = 1,
    alpha = 0.1,
    Correlations = TRUE,
    fixed_effects = TRUE,
    side_of_test = "two_sided",
    print = TRUE,
    ns = 200,
    dtw = 0,
    parallel = parallel,
    parallel_setup = "sequential",
    ProgressBar = FALSE,
    plot_best = FALSE
  )
}

run_market_selection <- function(data, treatment_periods) {
  if (has_ms) {
    fn <- GeoLiftMarketSelection
  } else if (exists("GeoLiftPowerFinder", mode = "function")) {
    fn <- GeoLiftPowerFinder
  } else {
    stop("Neither GeoLiftMarketSelection nor GeoLiftPowerFinder is available.")
  }
  args <- ms_args(data, treatment_periods, parallel = TRUE)
  tryCatch(
    invoke(fn, args),
    error = function(e) {
      message("Retry market selection with parallel = FALSE: ", conditionMessage(e))
      args$parallel <- FALSE
      invoke(fn, args)
    }
  )
}

best_from <- function(obj) {
  if (is.null(obj)) {
    return(NULL)
  }
  if (is.data.frame(obj)) {
    return(obj)
  }
  if (!is.null(obj$BestMarkets)) {
    return(as.data.frame(obj$BestMarkets))
  }
  if (!is.null(obj$results)) {
    return(as.data.frame(obj$results))
  }
  stop("Cannot find a ranking table on the market-selection object.")
}

market <- NULL
ms_error <- NULL
period_grid <- list(4L, c(4L, 10L))
for (periods in period_grid) {
  message("GeoLiftMarketSelection treatment_periods = ", paste(periods, collapse = ","))
  market <- tryCatch(
    run_market_selection(GeoTestData_PreTest, periods),
    error = function(e) {
      ms_error <<- e
      message("Market selection failed: ", conditionMessage(e))
      NULL
    }
  )
  if (!is.null(market)) {
    break
  }
}
if (is.null(market)) {
  stop(ms_error)
}

best <- best_from(market)
if (!nrow(best)) {
  stop("Market selection returned zero rows.")
}

# Column-name drift across GeoLift versions
nm <- names(best)
rename_if <- function(df, old, new) {
  if (old %in% names(df) && !new %in% names(df)) {
    names(df)[names(df) == old] <- new
  }
  df
}
best <- rename_if(best, "power", "Power")
best <- rename_if(best, "effect_size", "EffectSize")
if (!"rank" %in% names(best) && "ID" %in% names(best)) {
  best$rank <- best$ID
}
if (!"ProportionTotal_Y" %in% names(best)) {
  best$ProportionTotal_Y <- NA_real_
}

pick_row <- function(df) {
  ord <- seq_len(nrow(df))
  if ("rank" %in% names(df)) {
    ord <- order(df$rank, df$ID)
  } else if ("ID" %in% names(df)) {
    ord <- order(df$ID)
  }
  df <- df[ord, , drop = FALSE]
  refused_40 <- FALSE
  for (i in seq_len(nrow(df))) {
    py <- df$ProportionTotal_Y[i]
    if (!is.na(py) && py > 0.40) {
      refused_40 <- TRUE
      next
    }
    row <- df[i, , drop = FALSE]
    attr(row, "refused_40") <- refused_40
    return(row)
  }
  row <- df[1, , drop = FALSE]
  attr(row, "refused_40") <- TRUE
  row
}

chosen <- pick_row(best)
treatment_locations <- split_market_string(chosen$location)
if (!length(treatment_locations)) {
  stop("Could not parse treatment locations from ranking row.")
}
unknown <- setdiff(treatment_locations, pre_locs)
if (length(unknown)) {
  stop("Ranking returned names not in GeoTestData_PreTest: ", paste(unknown, collapse = ", "))
}

duration <- if ("duration" %in% names(chosen)) as.integer(chosen$duration[[1]]) else 4L
mde <- if ("EffectSize" %in% names(chosen)) as.numeric(chosen$EffectSize[[1]]) else NA_real_
pwr <- if ("Power" %in% names(chosen)) as.numeric(chosen$Power[[1]]) else NA_real_
investment <- if ("Investment" %in% names(chosen)) as.numeric(chosen$Investment[[1]]) else NA_real_
prop_y <- as.numeric(chosen$ProportionTotal_Y[[1]])
corr <- if ("correlation" %in% names(chosen)) as.numeric(chosen$correlation[[1]]) else NA_real_
scaled_l2 <- if ("AvgScaledL2Imbalance" %in% names(chosen)) {
  as.numeric(chosen$AvgScaledL2Imbalance[[1]])
} else {
  NA_real_
}

powered_5pct <- !is.na(mde) && !is.na(pwr) && mde <= 0.051 && pwr >= 0.80
design_note <- if (powered_5pct) {
  sprintf(
    "Rank-1 (after 40%% sales filter) can detect a %.0f%% MDE at power %.2f in %d periods.",
    100 * mde, pwr, duration
  )
} else {
  sprintf(
    "Four-period / small-grid design does not show a 5%% MDE at ~80%% power on this panel. Ranking MDE is %s at power %s over %d periods. Implied unit budget (cpic = 1 SAMPLE placeholder, incremental cash-sales units) is %s. Lengthen the window or raise spend before you treat 5%% as detectable. Inject still uses 4 periods so the CI can miss 8%% — that is the point.",
    ifelse(is.na(mde), "NA", sprintf("%.0f%%", 100 * mde)),
    ifelse(is.na(pwr), "NA", sprintf("%.2f", pwr)),
    duration,
    ifelse(is.na(investment), "NA", sprintf("%.0f", investment))
  )
}
message(design_note)

control_locations <- setdiff(pre_locs, treatment_locations)
markets_df <- rbind(
  data.frame(role = "treatment", location = treatment_locations, stringsAsFactors = FALSE),
  data.frame(role = "control", location = control_locations, stringsAsFactors = FALSE)
)
utils::write.csv(markets_df, file.path(out_dir, "markets.csv"), row.names = FALSE)

# --- Power curve for chosen markets (keep lookback = 1) ---
power_obj <- NULL
power_err <- NULL
if (exists("GeoLiftPower", mode = "function")) {
  power_args <- list(
    data = GeoTestData_PreTest,
    locations = treatment_locations,
    effect_size = c(0, 0.05, 0.08, 0.10, 0.15, 0.20),
    lookback_window = 1,
    treatment_periods = duration,
    cpic = 1,
    side_of_test = "two_sided",
    Y_id = "Y",
    location_id = "location",
    time_id = "time",
    alpha = 0.1,
    fixed_effects = TRUE,
    parallel = TRUE,
    parallel_setup = "sequential",
    ns = 200
  )
  power_obj <- tryCatch(
    invoke(GeoLiftPower, power_args),
    error = function(e) {
      message("GeoLiftPower parallel failed: ", conditionMessage(e))
      power_args$parallel <- FALSE
      tryCatch(
        invoke(GeoLiftPower, power_args),
        error = function(e2) {
          power_err <<- e2
          NULL
        }
      )
    }
  )
}

if (is.null(power_obj) && !is.null(market$PowerCurves)) {
  message("Writing PowerCurves from market selection (GeoLiftPower unavailable).")
  power_obj <- as.data.frame(market$PowerCurves)
}
if (is.null(power_obj)) {
  warning("No power curve object: ", if (!is.null(power_err)) conditionMessage(power_err) else "unknown")
  power_df <- data.frame(
    note = "power curve not produced",
    error = if (!is.null(power_err)) conditionMessage(power_err) else "unknown"
  )
} else if (is.data.frame(power_obj)) {
  power_df <- power_obj
} else {
  power_df <- as.data.frame(power_obj)
}
utils::write.csv(power_df, file.path(out_dir, "power.csv"), row.names = FALSE)

# --- Inject +8% on a copy of the PRE-TEST series, 4-period window ---
max_t <- max(GeoTestData_PreTest$time)
inject_end <- max_t
inject_start <- max_t - 4L + 1L
injected <- inject_relative_lift(
  data = GeoTestData_PreTest,
  locations = treatment_locations,
  treatment_start_time = inject_start,
  treatment_end_time = inject_end,
  lift = 0.08
)
message(
  "Injected +8% cash sales on ", attr(injected, "n_injected"),
  " rows, periods ", inject_start, "-", inject_end, "."
)

fit <- invoke(GeoLift, list(
  Y_id = "Y",
  time_id = "time",
  location_id = "location",
  data = injected,
  locations = treatment_locations,
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
))

att <- as.numeric(fit$inference$ATT[1])
pct <- as.numeric(fit$inference$Perc.Lift[1])
pval <- as.numeric(fit$inference$pvalue[1])
ci_lo_inc <- as.numeric(fit$lower_bound[1])
ci_hi_inc <- as.numeric(fit$upper_bound[1])
incremental <- as.numeric(fit$incremental[1])

pct_frac <- if (!is.na(pct)) pct / 100 else NA_real_
cf_total <- if (!is.na(pct_frac) && abs(pct_frac) > 1e-8) incremental / pct_frac else NA_real_
ci_lo_pct <- if (!is.na(cf_total) && abs(cf_total) > 1e-8) ci_lo_inc / cf_total else NA_real_
ci_hi_pct <- if (!is.na(cf_total) && abs(cf_total) > 1e-8) ci_hi_inc / cf_total else NA_real_

ci_ok <- !anyNA(c(ci_lo_pct, ci_hi_pct))
ci_covers_8 <- ci_ok && min(ci_lo_pct, ci_hi_pct) <= 0.08 && 0.08 <= max(ci_lo_pct, ci_hi_pct)
ci_positive <- !anyNA(c(ci_lo_inc, ci_hi_inc)) && ci_lo_inc > 0

miss_8_line <- if (!ci_ok) {
  "Confidence interval did not compute cleanly (conformal aggregate CI can fail on short windows). Do not scale from a missing CI."
} else if (ci_covers_8) {
  "90% CI covers the injected +8%. Recovered range is wide or tight depending on power — still read p and cash MER before scaling."
} else {
  sprintf(
    "90% CI MISSES the injected +8%% (CI on lift about %.1f%% to %.1f%%; point estimate %.1f%%). That is the point of this SAMPLE: a four-period window can be the wrong design even when you know the truth.",
    100 * ci_lo_pct, 100 * ci_hi_pct, pct
  )
}

att_df <- data.frame(
  metric = c(
    "att",
    "percent_lift",
    "pvalue",
    "incremental_cash_sales",
    "ci_lower_incremental",
    "ci_upper_incremental",
    "ci_lower_pct",
    "ci_upper_pct",
    "injected_lift",
    "ci_covers_injected_8pct",
    "alpha",
    "treatment_start",
    "treatment_end",
    "n_treatment_markets",
    "geolift_version"
  ),
  value = c(
    att,
    pct,
    pval,
    incremental,
    ci_lo_inc,
    ci_hi_inc,
    ci_lo_pct,
    ci_hi_pct,
    0.08,
    as.integer(ci_covers_8),
    0.1,
    inject_start,
    inject_end,
    length(treatment_locations),
    geolift_ver
  ),
  stringsAsFactors = FALSE
)
utils::write.csv(att_df, file.path(out_dir, "att.csv"), row.names = FALSE)

# --- SAMPLE charts ---
save_png <- function(path, expr) {
  grDevices::png(filename = path, width = 1400, height = 900, res = 140)
  on.exit(try(grDevices::dev.off(), silent = TRUE), add = TRUE)
  obj <- tryCatch(expr, error = function(e) {
    plot.new()
    title(main = paste("SAMPLE: plot failed —", conditionMessage(e)))
    NULL
  })
  if (inherits(obj, "ggplot")) {
    print(obj)
  }
  invisible(obj)
}

panel_df <- GeoTestData_PreTest
panel_df$in_treatment <- ifelse(
  tolower(panel_df$location) %in% treatment_locations,
  "treatment",
  "control"
)
save_png(
  file.path(out_dir, "SAMPLE-panel.png"),
  ggplot(panel_df, aes(x = time, y = Y, group = location, color = in_treatment)) +
    geom_line(alpha = 0.45, size = 0.3) +
    geom_vline(xintercept = inject_start, linetype = "dashed") +
    scale_color_manual(values = c(control = "#6B6B6B", treatment = "#1F4E79")) +
    labs(
      title = "SAMPLE: cash sales by market (package Y)",
      subtitle = "GeoLift vignette panel — not client data",
      x = "time",
      y = "cash sales (Y)",
      color = NULL
    ) +
    theme_minimal() +
    theme(legend.position = "bottom")
)

if (!is.null(power_obj) && inherits(power_obj, "GeoLiftPower")) {
  save_png(
    file.path(out_dir, "SAMPLE-power.png"),
    {
      p <- plot(power_obj, show_mde = TRUE, smoothed_values = TRUE, breaks_x_axis = 5)
      if (inherits(p, "ggplot")) {
        p + labs(title = "SAMPLE: GeoLift power curve — 5% MDE target")
      } else {
        p
      }
    }
  )
} else if (is.data.frame(power_df) && all(c("EffectSize", "power") %in% names(power_df))) {
  agg <- aggregate(power ~ EffectSize, data = power_df, FUN = mean, na.rm = TRUE)
  save_png(
    file.path(out_dir, "SAMPLE-power.png"),
    ggplot(agg, aes(x = EffectSize, y = power)) +
      geom_line() +
      geom_point() +
      geom_hline(yintercept = 0.8, linetype = "dashed") +
      geom_vline(xintercept = 0.05, linetype = "dotted") +
      labs(
        title = "SAMPLE: GeoLift power curve — 5% MDE target",
        subtitle = "Dashed = 80% power; dotted = 5% MDE",
        x = "effect size",
        y = "power"
      ) +
      theme_minimal()
  )
}

save_png(
  file.path(out_dir, "SAMPLE-lift.png"),
  plot(
    fit,
    type = "Lift",
    title = "SAMPLE: treated vs synthetic cash sales (+8% inject)",
    subtitle = paste(treatment_locations, collapse = ", "),
    notes = "SAMPLE — not client data"
  )
)
save_png(
  file.path(out_dir, "SAMPLE-att.png"),
  plot(
    fit,
    type = "ATT",
    title = "SAMPLE: ATT after +8% cash-sales inject (4 periods)",
    subtitle = "If the CI misses 8%, say so — that is the point",
    notes = "SAMPLE — not client data"
  )
)

# --- CMO brief (overwrites the static protocol copy) ---
decision <- if (!is.na(pval) && pval < 0.10 && ci_positive && ci_covers_8) {
  "SCALE the geo-assignable cell if cash MER on the incremental still clears. Do not raise every platform off this ATT."
} else if (!is.na(pval) && pval < 0.10 && ci_positive && !ci_covers_8) {
  "CUT the 'we recovered 8%' story. Significant lift is not the same as recovering the injected 8%. Rerun a longer window before you scale to that number."
} else if (!is.na(pval) && pval < 0.10 && !ci_positive) {
  "CUT scale. p is under 0.10 but the incremental CI is not cleanly above zero. Do not spend against a contradiction between p and CI."
} else {
  "CUT scale on this evidence. Rerun: four periods were likely underpowered for a 5% MDE. Lengthen the holdout or raise spend. Do not stuff this ATT into an MMM as validation."
}

elapsed <- round(as.numeric(difftime(Sys.time(), t0_wall, units = "mins")), 2)
tx_line <- paste(treatment_locations, collapse = ", ")
ctl_n <- length(control_locations)

cmo <- paste0(
  "SAMPLE: CMO brief — scale / cut / rerun\n\n",
  "Not client data. Not Black Clover. facebookincubator/GeoLift ", geolift_ver,
  " vignette panel. KPI is **cash sales** (package column Y). Runtime ", elapsed, " minutes.\n\n",
  "## One geo test (interview)\n\n",
  "- **Markets (treatment):** ", tx_line, "\n",
  "- **Control:** ", ctl_n, " remaining complete cities in GeoTestData_PreTest",
  if ("honolulu" %in% control_locations) " (Honolulu held in the control pool, not treatment — package walkthrough)." else ".",
  "\n",
  "- **KPI:** cash sales.\n",
  "- **Window:** periods ", inject_start, "–", inject_end, " (4 periods) on a copy of the pre-test series.\n",
  "- **Injected truth:** +8%.\n",
  "- **Result:** ATT = ", round(att, 3),
  "; percent lift = ", round(pct, 2), "%",
  "; incremental cash sales = ", round(incremental, 1),
  "; p = ", signif(pval, 3),
  "; 90% CI (incremental) = (", round(ci_lo_inc, 1), ", ", round(ci_hi_inc, 1), ").\n",
  "- **CI covers 8%?** ", if (ci_covers_8) "yes" else "no", ". ", miss_8_line, "\n",
  "- **API:** ", api_note, ".\n\n",
  "## Design vs 5% MDE\n\n",
  design_note, "\n\n",
  "Pre-period fit: scaled L2 imbalance ",
  ifelse(is.na(scaled_l2), "NA", round(scaled_l2, 3)),
  "; test vs rest-of-panel correlation ",
  ifelse(is.na(corr), "NA", round(corr, 3)),
  "; treatment share of cash sales ",
  ifelse(is.na(prop_y), "NA", sprintf("%.1f%%", 100 * prop_y)),
  ".\n\n",
  "## What I would cut\n\n",
  "- A market that is ~40% of cash sales. ",
  if (isTRUE(attr(chosen, "refused_40"))) {
    "At least one higher rank was skipped for that reason.\n"
  } else {
    "This rank is under that cap.\n"
  },
  "- Overlapping media: treatment geos that still see the tactic. SAMPLE data cannot show the buy; I would refuse it on a live desk.\n",
  "- National TV and always-on brand I will not pause. GeoLift does not identify them.\n",
  "- Meta all-up if the MMM splits ASC vs prospecting. An all-up ATT cannot anchor either curve.\n\n",
  "## Scale / cut / rerun\n\n",
  decision, "\n\n",
  "Haus vs Recast: experiment results **anchor** the response curve. Recast “validate the model” is the opposite order. See `out/mmm-first-vs-geolift-first.md`.\n"
)
writeLines(cmo, file.path(out_dir, "CMO-brief.md"))

message("Wrote out/power.csv, out/markets.csv, out/att.csv, out/CMO-brief.md, SAMPLE PNGs.")
message("Elapsed minutes: ", elapsed)
if (elapsed > 20) {
  warning("Runtime exceeded 20 minutes. Shrink N / effect_size / ns further.")
}
