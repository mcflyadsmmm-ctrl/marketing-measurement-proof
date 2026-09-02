#!/usr/bin/env Rscript
# SAMPLE: Recast-style R pipeline — lm + geometric adstock.
# Not a ~30k-parameter Bayesian MMM. Not Robyn.

find_root <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) == 1L) {
    script <- normalizePath(sub("^--file=", "", file_arg[[1]]), mustWork = TRUE)
    return(normalizePath(file.path(dirname(script), "..")))
  }
  if (file.exists("R/run.R")) {
    return(normalizePath("."))
  }
  if (file.exists("run.R") && file.exists(file.path("..", "README.md"))) {
    return(normalizePath(".."))
  }
  normalizePath(".")
}

root <- find_root()
setwd(root)

needed <- c("dplyr", "readr", "ggplot2", "broom", "lubridate", "tibble", "tidyr")
installed <- rownames(utils::installed.packages())
missing <- needed[!needed %in% installed]
if (length(missing) > 0L) {
  message("Installing missing packages from cloud.r-project.org: ", paste(missing, collapse = ", "))
  utils::install.packages(missing, repos = "https://cloud.r-project.org")
}

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(ggplot2)
  library(broom)
  library(lubridate)
  library(tibble)
  library(tidyr)
})

source(file.path(root, "R", "adstock.R"))
source(file.path(root, "R", "make_sample.R"))
source(file.path(root, "R", "write_outputs.R"))

data_dir <- file.path(root, "data")
out_dir <- file.path(root, "out")
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

csv_path <- file.path(data_dir, "sample_weekly.csv")
if (!file.exists(csv_path)) {
  message("SAMPLE CSV missing — generating with set.seed(2020).")
  make_sample(csv_path)
} else {
  message("SAMPLE CSV found: ", csv_path)
}

raw <- readr::read_csv(csv_path, show_col_types = FALSE) %>%
  mutate(week = as.Date(.data$week)) %>%
  arrange(.data$week)

required_cols <- c(
  "week", "spend_google", "spend_meta", "spend_tiktok", "spend_amazon",
  "promo_flag", "cash_sales", "platform_reported_conversions"
)
stopifnot(all(required_cols %in% names(raw)))
stopifnot(nrow(raw) == 104L)
stopifnot(as.Date(min(raw$week)) == as.Date("2023-01-02"))
stopifnot(lubridate::wday(min(raw$week), week_start = 1) == 1)

n <- nrow(raw)
miss <- colSums(is.na(raw))
miss_pct <- miss / n

cat("\n========== SAMPLE diagnostics ==========\n")
cat("R:", R.version.string, "\n")
cat("Rows:", n, "  ", as.character(min(raw$week)), "to", as.character(max(raw$week)), "\n")
cat("\nMissingness (count, pct):\n")
print(tibble(column = names(miss), n_missing = as.integer(miss), pct = miss_pct))

df <- raw %>%
  mutate(
    spend_google = ifelse(is.na(.data$spend_google), 0, .data$spend_google),
    spend_meta = ifelse(is.na(.data$spend_meta), 0, .data$spend_meta),
    spend_tiktok = ifelse(is.na(.data$spend_tiktok), 0, .data$spend_tiktok),
    spend_amazon = ifelse(is.na(.data$spend_amazon), 0, .data$spend_amazon)
  )

stopifnot(!anyNA(df$spend_google), !anyNA(df$spend_meta), !anyNA(df$spend_tiktok), !anyNA(df$spend_amazon))
stopifnot(!anyNA(df$cash_sales), !anyNA(df$promo_flag))

total_spend <- with(df, spend_google + spend_meta + spend_tiktok + spend_amazon)
share <- c(
  google = sum(df$spend_google) / sum(total_spend),
  meta = sum(df$spend_meta) / sum(total_spend),
  tiktok = sum(df$spend_tiktok) / sum(total_spend),
  amazon = sum(df$spend_amazon) / sum(total_spend)
)
cat("\nSpend share:\n")
print(tibble(channel = names(share), share = as.numeric(share), pct = 100 * as.numeric(share)))

cor_platform_cash <- cor(
  df$platform_reported_conversions,
  df$cash_sales,
  use = "pairwise.complete.obs"
)
implied_orders <- df$cash_sales / 68
cor_platform_orders <- cor(
  df$platform_reported_conversions,
  implied_orders,
  use = "pairwise.complete.obs"
)
ok <- !is.na(df$platform_reported_conversions)
claim_inflation <- mean(df$platform_reported_conversions[ok]) / mean(implied_orders[ok])

cat("\nPlatform conversions vs cash (they will not match):\n")
cat(sprintf("  cor(platform_reported_conversions, cash_sales) = %.3f\n", cor_platform_cash))
cat(sprintf("  cor(platform_reported_conversions, cash_sales/68) = %.3f\n", cor_platform_orders))
cat(sprintf("  mean(claimed) / mean(cash/AOV) = %.3f  (1.0 would match; >1 is double-count)\n", claim_inflation))
cat(sprintf("  mean cash_sales = %.0f   mean claimed conversions = %.0f   mean implied orders = %.0f\n",
            mean(df$cash_sales), mean(df$platform_reported_conversions, na.rm = TRUE), mean(implied_orders)))

rmse <- function(y, yhat) {
  sqrt(mean((y - yhat)^2))
}

apply_adstock <- function(d, theta) {
  d %>%
    mutate(
      ads_google = geometric_adstock(.data$spend_google, theta),
      ads_meta = geometric_adstock(.data$spend_meta, theta),
      ads_tiktok = geometric_adstock(.data$spend_tiktok, theta),
      ads_amazon = geometric_adstock(.data$spend_amazon, theta)
    )
}

form <- cash_sales ~ ads_google + ads_meta + ads_tiktok + ads_amazon + promo_flag
train_idx <- 1:91
test_idx <- 92:104
thetas <- c(0.3, 0.5, 0.7)

grid <- purrr::map_dfr(thetas, function(th) {
  d <- apply_adstock(df, th)
  train <- d[train_idx, , drop = FALSE]
  test <- d[test_idx, , drop = FALSE]
  fit <- lm(form, data = train)
  pred <- predict(fit, newdata = test)
  tibble(theta = th, holdout_rmse = rmse(test$cash_sales, pred))
})

print(grid)
best_theta <- grid$theta[which.min(grid$holdout_rmse)]
best_rmse <- min(grid$holdout_rmse)
cat(sprintf("\nChosen theta = %s  (min holdout RMSE = %.1f on weeks 92–104)\n",
            format(best_theta), best_rmse))

d_best <- apply_adstock(df, best_theta)
train <- d_best[train_idx, , drop = FALSE]
fit <- lm(form, data = train)

tidy_fit <- broom::tidy(fit, conf.int = TRUE, conf.level = 0.95)
glance_fit <- broom::glance(fit)
vif_tbl <- vif_from_lm(fit)

cat("\nOLS coefficients (train weeks 1–91), 95% CI:\n")
print(tidy_fit)
cat("\nVIF (base-R auxiliary regressions, no car):\n")
print(vif_tbl)
cat(sprintf("\nTrain R-squared = %.3f   holdout RMSE = %.1f\n", glance_fit$r.squared, best_rmse))

readr::write_csv(tidy_fit, file.path(out_dir, "tidy.csv"))
readr::write_csv(vif_tbl, file.path(out_dir, "vif.csv"))
readr::write_csv(grid, file.path(out_dir, "theta_grid.csv"))

spend_tidy <- tidy_fit %>%
  filter(.data$term %in% c("ads_google", "ads_meta", "ads_tiktok", "ads_amazon"))

plan <- build_channel_plan(spend_tidy)

train_spend_tot <- with(train, sum(spend_google + spend_meta + spend_tiktok + spend_amazon))
diagnostics <- list(
  theta = best_theta,
  holdout_rmse = best_rmse,
  cor_platform_cash = cor_platform_cash,
  claim_inflation = claim_inflation,
  miss_tiktok = miss_pct[["spend_tiktok"]],
  miss_platform = miss_pct[["platform_reported_conversions"]],
  share_google = sum(train$spend_google) / train_spend_tot,
  share_meta = sum(train$spend_meta) / train_spend_tot,
  share_tiktok = sum(train$spend_tiktok) / train_spend_tot,
  share_amazon = sum(train$spend_amazon) / train_spend_tot
)

write_priors(file.path(out_dir, "priors.md"))
write_experiment(file.path(out_dir, "experiment.md"), plan, train, best_theta, glance_fit)
memo_lines <- write_cmo_memo(
  file.path(out_dir, "CMO-memo.md"),
  plan, tidy_fit, glance_fit, vif_tbl, diagnostics
)
write_plots(d_best, spend_tidy, out_dir)

n_words <- attr(memo_lines, "word_count")
cat(sprintf("\nWrote out/CMO-memo.md (%s words, cap 800)\n", n_words))
cat("Wrote out/priors.md\n")
cat("Wrote out/experiment.md\n")
cat("Wrote out/spend_vs_cash.png, claimed_vs_cash.png, coefficients.png\n")
cat("SAMPLE pipeline done. Widest-CI channel:", plan$widest$channel, "\n")
cat("========================================\n")
