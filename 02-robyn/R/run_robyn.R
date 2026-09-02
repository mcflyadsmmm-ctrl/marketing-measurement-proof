# SAMPLE: Meta Robyn on package dt_simulated_weekly.
# Official demo API: https://github.com/facebookexperimental/Robyn/blob/main/demo/demo.R
# Timeboxed Nevergrad. Production uses 2000 iterations x 5 trials (demo.R).

LAPTOP_ITERATIONS <- 200L
LAPTOP_TRIALS <- 1L
PRODUCTION_ITERATIONS <- 2000L
PRODUCTION_TRIALS <- 5L
HOLDOUT_WEEKS <- 10L
WINDOW_START <- "2016-01-01"
WINDOW_END <- "2018-12-31"

nevergrad_install_msg <- paste(
  c(
    "Robyn requires the Python library Nevergrad.",
    "Official guide: https://github.com/facebookexperimental/Robyn/blob/main/demo/install_nevergrad.R",
    "Official README: https://github.com/facebookexperimental/Robyn",
    "",
    "Option 1 (pip / reticulate), from that guide:",
    "  install.packages(\"reticulate\")",
    "  library(\"reticulate\")",
    "  virtualenv_create(\"r-reticulate\")",
    "  use_virtualenv(\"r-reticulate\", required = TRUE)",
    "  Sys.setenv(RETICULATE_PYTHON = \"~/.virtualenvs/r-reticulate/bin/python\")",
    "  py_install(\"numpy\", pip = TRUE)",
    "  py_install(\"nevergrad\", pip = TRUE)",
    "",
    "Note from install_nevergrad.R: Python 3.10+ may cause a Nevergrad error."
  ),
  collapse = "\n"
)

robyn_install_msg <- paste(
  c(
    "Package Robyn is not installed. Exact install from the official README:",
    "https://github.com/facebookexperimental/Robyn",
    "",
    "## CRAN VERSION",
    "install.packages(\"Robyn\")",
    "",
    "## DEV VERSION",
    "# If you don't have remotes installed yet, first run: install.packages(\"remotes\")",
    "remotes::install_github(\"facebookexperimental/Robyn/R\")",
    "",
    nevergrad_install_msg
  ),
  collapse = "\n"
)

script_root <- (function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) == 1L) {
    return(dirname(dirname(normalizePath(sub("^--file=", "", file_arg)))))
  }
  if (file.exists(file.path(getwd(), "R", "run_robyn.R"))) {
    return(normalizePath(getwd()))
  }
  if (file.exists("run_robyn.R")) {
    return(normalizePath(".."))
  }
  normalizePath(getwd())
})()

out_dir <- file.path(script_root, "out")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

write_stub <- function(filename, body) {
  writeLines(body, file.path(out_dir, filename))
}

write_stub(
  "holdout_mape.txt",
  paste(
    c(
      "SAMPLE: holdout MAPE not computed yet.",
      "Robyn has not finished a model on this machine. No MAPE number is reported."
    ),
    collapse = "\n"
  )
)

write_stub(
  "allocator_notes.md",
  paste(
    c(
      "# SAMPLE: Robyn Allocator",
      "",
      "Allocator did not run. No current vs recommended spend is reported.",
      "Do not invent dollars. See ../README.md for install + `Rscript R/run_robyn.R`.",
      "",
      "Decision memo: [`../../03-meridian/out/decision.md`](../../03-meridian/out/decision.md)"
    ),
    collapse = "\n"
  )
)

if (!requireNamespace("Robyn", quietly = TRUE)) {
  message(robyn_install_msg)
  quit(save = "no", status = 1L)
}

library(Robyn)

# python.org 3.11 is now first on PATH. Nevergrad lives on Apple 3.9.
ng_python <- path.expand("~/.virtualenvs/r-reticulate/bin/python")
if (file.exists(ng_python)) {
  Sys.setenv(RETICULATE_PYTHON = ng_python)
}

ng_ok <- FALSE
try(
  {
    if (requireNamespace("reticulate", quietly = TRUE)) {
      if (file.exists(ng_python)) {
        reticulate::use_virtualenv("r-reticulate", required = TRUE)
      }
      ng_ok <- isTRUE(reticulate::py_module_available("nevergrad"))
    }
  },
  silent = TRUE
)
if (!isTRUE(ng_ok)) {
  message(nevergrad_install_msg)
  quit(save = "no", status = 1L)
}

message(
  "SAMPLE: laptop Nevergrad is ",
  LAPTOP_ITERATIONS,
  " iterations x ",
  LAPTOP_TRIALS,
  " trial. Production (demo.R) is ",
  PRODUCTION_ITERATIONS,
  " x ",
  PRODUCTION_TRIALS,
  "."
)

data("dt_simulated_weekly", package = "Robyn")
data("dt_prophet_holidays", package = "Robyn")

dt <- dt_simulated_weekly
dt$DATE <- as.Date(dt$DATE)
win <- dt[dt$DATE >= as.Date(WINDOW_START) & dt$DATE <= as.Date(WINDOW_END), ]
win_dates <- sort(unique(win$DATE))
if (length(win_dates) <= HOLDOUT_WEEKS) {
  stop("SAMPLE window is too short for a last-10-week holdout.")
}
holdout_dates <- utils::tail(win_dates, HOLDOUT_WEEKS)
train_end <- win_dates[length(win_dates) - HOLDOUT_WEEKS]

# Geometric hyps from official demo.R (facebookexperimental/Robyn).
hyperparameters <- list(
  facebook_I_alphas = c(0.5, 3),
  facebook_I_gammas = c(0.3, 1),
  facebook_I_thetas = c(0, 0.3),
  print_S_alphas = c(0.5, 1),
  print_S_gammas = c(0.3, 1),
  print_S_thetas = c(0.1, 0.4),
  tv_S_alphas = c(0.5, 1),
  tv_S_gammas = c(0.3, 1),
  tv_S_thetas = c(0.3, 0.8),
  search_clicks_P_alphas = c(0.5, 3),
  search_clicks_P_gammas = c(0.3, 1),
  search_clicks_P_thetas = c(0, 0.3),
  ooh_S_alphas = c(0.5, 1),
  ooh_S_gammas = c(0.3, 1),
  ooh_S_thetas = c(0.1, 0.4),
  newsletter_alphas = c(0.5, 3),
  newsletter_gammas = c(0.3, 1),
  newsletter_thetas = c(0.1, 0.4),
  train_size = c(0.8, 0.8)
)

InputCollect <- robyn_inputs(
  dt_input = dt_simulated_weekly,
  dt_holidays = dt_prophet_holidays,
  date_var = "DATE",
  dep_var = "revenue",
  dep_var_type = "revenue",
  prophet_vars = c("trend", "season", "holiday"),
  prophet_country = "DE",
  context_vars = c("competitor_sales_B", "events"),
  paid_media_spends = c("tv_S", "ooh_S", "print_S", "facebook_S", "search_S"),
  paid_media_vars = c("tv_S", "ooh_S", "print_S", "facebook_I", "search_clicks_P"),
  organic_vars = c("newsletter"),
  factor_vars = c("events"),
  window_start = WINDOW_START,
  window_end = as.character(train_end),
  adstock = "geometric",
  hyperparameters = hyperparameters
)

OutputModels <- robyn_run(
  InputCollect = InputCollect,
  cores = 1,
  iterations = LAPTOP_ITERATIONS,
  trials = LAPTOP_TRIALS,
  ts_validation = TRUE,
  add_penalty_factor = FALSE,
  seed = 123L
)

OutputCollect <- robyn_outputs(
  InputCollect,
  OutputModels,
  pareto_fronts = 1,
  clusters = FALSE,
  csv_out = "pareto",
  export = TRUE,
  plot_folder = out_dir,
  plot_pareto = TRUE
)

hyps <- OutputCollect$resultHypParam
if (is.null(hyps) || nrow(hyps) < 1) {
  stop("SAMPLE: robyn_outputs returned no Pareto rows. Will not invent a model id.")
}
nrmse_col <- if ("nrmse" %in% names(hyps)) "nrmse" else names(hyps)[grep("nrmse", names(hyps), ignore.case = TRUE)][1]
select_model <- as.character(hyps$solID[order(hyps[[nrmse_col]])[1]])

mape_lines <- c(
  "SAMPLE: Robyn holdout MAPE — last 10 weeks of dt_simulated_weekly demo window.",
  paste0("Train window_end: ", as.character(train_end), " (holdout ", HOLDOUT_WEEKS, " weeks not in robyn_inputs window)."),
  paste0("Holdout dates: ", paste(as.character(range(holdout_dates)), collapse = " to "), "."),
  paste0("Selected solID: ", select_model, "."),
  paste0(
    "Nevergrad: ", LAPTOP_ITERATIONS, " iterations x ", LAPTOP_TRIALS,
    " trial (laptop). Production demo.R: ", PRODUCTION_ITERATIONS, " x ", PRODUCTION_TRIALS, "."
  )
)

holdout_mape_value <- NA_real_
holdout_note <- "MAPE not computed."

try(
  {
    vec <- OutputCollect$xDecompVecCollect
    vec <- vec[as.character(vec$solID) == select_model, , drop = FALSE]
    date_col <- if ("ds" %in% names(vec)) "ds" else if ("DATE" %in% names(vec)) "DATE" else NULL
    if (!is.null(date_col) && "dep_var" %in% names(vec) && "depVarHat" %in% names(vec) && nrow(vec) >= HOLDOUT_WEEKS) {
      vec[[date_col]] <- as.Date(vec[[date_col]])
      vec <- vec[order(vec[[date_col]]), ]
      last <- utils::tail(vec, HOLDOUT_WEEKS)
      actual <- as.numeric(last$dep_var)
      pred <- as.numeric(last$depVarHat)
      holdout_mape_value <- mean(abs(actual - pred) / pmax(abs(actual), 1e-8))
      holdout_note <- paste0(
        "Trailing ", HOLDOUT_WEEKS,
        " weeks of the TRAIN window decomposition (dep_var vs depVarHat). ",
        "True holdout weeks after window_end are not in xDecompVec; see frozen-hyp block."
      )
    }
  },
  silent = TRUE
)

# Frozen hyps + ridge coefs on the excluded last 10 weeks (no Nevergrad refit).
try(
  {
    agg <- OutputCollect$xDecompAgg
    agg <- agg[as.character(agg$solID) == select_model, , drop = FALSE]
    if (nrow(agg) < 1 || !all(c("rn", "coef") %in% names(agg))) {
      stop("no coef table")
    }
    coefs <- stats::setNames(as.numeric(agg$coef), as.character(agg$rn))
    hrow <- hyps[as.character(hyps$solID) == select_model, , drop = FALSE]
    full <- dt[dt$DATE >= as.Date(WINDOW_START) & dt$DATE <= as.Date(WINDOW_END), ]
    full <- full[order(full$DATE), ]
    is_hold <- full$DATE %in% holdout_dates

    adstock_sat <- function(x, theta, alpha, gamma) {
      ads <- adstock_geometric(x = as.numeric(x), theta = theta)
      decayed <- if (is.list(ads) && "x_decayed" %in% names(ads)) ads$x_decayed else ads
      sat <- saturation_hill(x = as.numeric(decayed), alpha = alpha, gamma = gamma)
      if (is.list(sat) && "x_saturated" %in% names(sat)) sat <- sat$x_saturated
      as.numeric(sat)
    }

    media_map <- list(
      tv_S = c("tv_S_thetas", "tv_S_alphas", "tv_S_gammas"),
      ooh_S = c("ooh_S_thetas", "ooh_S_alphas", "ooh_S_gammas"),
      print_S = c("print_S_thetas", "print_S_alphas", "print_S_gammas"),
      facebook_I = c("facebook_I_thetas", "facebook_I_alphas", "facebook_I_gammas"),
      search_clicks_P = c("search_clicks_P_thetas", "search_clicks_P_alphas", "search_clicks_P_gammas"),
      newsletter = c("newsletter_thetas", "newsletter_alphas", "newsletter_gammas")
    )
    intercept_name <- intersect(
      c("(Intercept)", "intercept", "Intercept"),
      names(coefs)
    )
    intercept <- if (length(intercept_name)) unname(coefs[[intercept_name[[1]]]]) else 0
    if (!is.finite(intercept)) intercept <- 0
    yhat <- rep(intercept, nrow(full))
    for (nm in names(media_map)) {
      if (!nm %in% names(full) || !nm %in% names(coefs)) next
      keys <- media_map[[nm]]
      if (!all(keys %in% names(hrow))) next
      sat <- adstock_sat(
        full[[nm]],
        theta = as.numeric(hrow[[keys[1]]]),
        alpha = as.numeric(hrow[[keys[2]]]),
        gamma = as.numeric(hrow[[keys[3]]])
      )
      yhat <- yhat + coefs[[nm]] * as.numeric(sat)
    }
    for (ctx in c("competitor_sales_B")) {
      if (ctx %in% names(full) && ctx %in% names(coefs)) {
        yhat <- yhat + coefs[[ctx]] * as.numeric(full[[ctx]])
      }
    }
    actual_h <- as.numeric(full$revenue[is_hold])
    mape_hold <- mean(abs(actual_h - yhat[is_hold]) / pmax(abs(actual_h), 1e-8))
    holdout_mape_value <- mape_hold
    holdout_note <- paste0(
      "Holdout MAPE on last ", HOLDOUT_WEEKS,
      " weeks using frozen Nevergrad hyps + ridge coefs. ",
      "Adstock/Hill run on the full SAMPLE window so carryover into holdout is kept; ",
      "Prophet seasonal terms are omitted. Not an Allocator dollar."
    )
  },
  silent = TRUE
)

if (is.finite(holdout_mape_value)) {
  mape_lines <- c(
    mape_lines,
    sprintf("MAPE: %.4f (%.2f%%).", holdout_mape_value, 100 * holdout_mape_value),
    holdout_note
  )
} else {
  mape_lines <- c(
    mape_lines,
    "MAPE: not computed (scoring failed). No number is invented.",
    holdout_note
  )
}
writeLines(mape_lines, file.path(out_dir, "holdout_mape.txt"))

try(
  {
    one <- robyn_onepagers(
      InputCollect,
      OutputCollect,
      select_model = select_model,
      export = TRUE,
      plot_folder = out_dir
    )
    if (requireNamespace("ggplot2", quietly = TRUE) && requireNamespace("patchwork", quietly = TRUE)) {
      p <- one[[select_model]]
      p <- p + patchwork::plot_annotation(
        title = "SAMPLE: Robyn OnePager (dt_simulated_weekly)"
      )
      ggplot2::ggsave(
        file.path(out_dir, "SAMPLE_robyn_onepager.png"),
        p,
        width = 16,
        height = 14,
        dpi = 120,
        limitsize = FALSE
      )
    }
  },
  silent = TRUE
)

try(
  {
    resp <- robyn_response(
      InputCollect = InputCollect,
      OutputCollect = OutputCollect,
      select_model = select_model,
      metric_name = "facebook_I"
    )
    if (!is.null(resp$plot) && requireNamespace("ggplot2", quietly = TRUE)) {
      p <- resp$plot + ggplot2::labs(title = "SAMPLE: Robyn saturation / response — facebook_I")
      ggplot2::ggsave(
        file.path(out_dir, "SAMPLE_robyn_saturation_facebook_I.png"),
        p,
        width = 8,
        height = 5,
        dpi = 120
      )
    }
  },
  silent = TRUE
)

try(
  {
    if (requireNamespace("ggplot2", quietly = TRUE)) {
      p_sat <- plot_saturation(plot = FALSE)
      if (inherits(p_sat, "ggplot")) {
        p_sat <- p_sat + ggplot2::labs(title = "SAMPLE: Robyn Hill saturation (generic)")
        ggplot2::ggsave(
          file.path(out_dir, "SAMPLE_robyn_hill_saturation.png"),
          p_sat,
          width = 8,
          height = 5,
          dpi = 120
        )
      }
    }
  },
  silent = TRUE
)

alloc_notes <- c(
  "# SAMPLE: Robyn Allocator — current vs recommended",
  "",
  paste0("select_model: `", select_model, "`."),
  paste0(
    "Laptop Nevergrad: ", LAPTOP_ITERATIONS, " x ", LAPTOP_TRIALS,
    ". Do not treat this mix as production."
  ),
  "Scenario: `max_response` on `date_range = \"last_10\"` of the **train** window (official demo.R).",
  "",
  "Decision: [`../../03-meridian/out/decision.md`](../../03-meridian/out/decision.md)"
)

try(
  {
    AllocatorCollect <- robyn_allocator(
      InputCollect = InputCollect,
      OutputCollect = OutputCollect,
      select_model = select_model,
      date_range = "last_10",
      channel_constr_low = 0.7,
      channel_constr_up = 1.5,
      scenario = "max_response",
      export = TRUE,
      plot_folder = out_dir
    )
    opt <- AllocatorCollect$dt_optimOut
    if (!is.null(opt)) {
      utils::write.csv(
        opt,
        file.path(out_dir, "allocator_current_vs_recommended.csv"),
        row.names = FALSE
      )
      alloc_notes <- c(
        alloc_notes,
        "",
        "Wrote `allocator_current_vs_recommended.csv` from `AllocatorCollect$dt_optimOut` (library output, not invented)."
      )
      spend_cols <- intersect(
        c(
          "channels", "channel", "initSpendUnit", "optmSpendUnit",
          "histSpendUnit", "expSpendUnit", "initSpend", "optmSpend"
        ),
        names(opt)
      )
      if (length(spend_cols) > 0) {
        alloc_notes <- c(alloc_notes, "", "Columns present:", paste(spend_cols, collapse = ", "))
      }
    } else {
      alloc_notes <- c(
        alloc_notes,
        "",
        "`dt_optimOut` was NULL. No recommended spend is written."
      )
    }
    if (requireNamespace("ggplot2", quietly = TRUE)) {
      p_a <- plot(AllocatorCollect)
      if (inherits(p_a, "ggplot") || inherits(p_a, "patchwork")) {
        if (inherits(p_a, "patchwork") && requireNamespace("patchwork", quietly = TRUE)) {
          p_a <- p_a + patchwork::plot_annotation(
            title = "SAMPLE: Robyn Allocator current vs recommended"
          )
        } else if (inherits(p_a, "ggplot")) {
          p_a <- p_a + ggplot2::labs(title = "SAMPLE: Robyn Allocator current vs recommended")
        }
        ggplot2::ggsave(
          file.path(out_dir, "SAMPLE_robyn_allocator.png"),
          p_a,
          width = 12,
          height = 8,
          dpi = 120,
          limitsize = FALSE
        )
      }
    }
  },
  silent = TRUE
)

if (!file.exists(file.path(out_dir, "allocator_current_vs_recommended.csv"))) {
  alloc_notes <- c(
    alloc_notes,
    "",
    "Allocator CSV was not written. No current vs recommended dollars are reported."
  )
}

writeLines(alloc_notes, file.path(out_dir, "allocator_notes.md"))
message("SAMPLE: Robyn artifacts in ", out_dir)
