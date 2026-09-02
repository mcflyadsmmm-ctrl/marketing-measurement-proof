# SAMPLE weekly panel. Known DGP is documented in README.md.
# Do not copy true betas into the CMO memo.

make_sample <- function(path) {
  set.seed(2020)

  n <- 104L
  week <- seq.Date(from = lubridate::ymd("2023-01-02"), by = "week", length.out = n)
  t <- seq_len(n)

  # Mild annual seasonality + Q4 lift. Idiosyncratic noise so channels are not clones.
  season <- 1 + 0.08 * sin(2 * pi * t / 52) +
    0.14 * as.numeric((t %% 52) >= 44 | (t %% 52) <= 2)
  trend <- 1 + 0.0018 * t

  spend_google <- round(
    pmax(
      7000,
      14500 * season * trend * exp(rnorm(n, 0, 0.11)) +
        6000 * as.numeric(t %in% c(18L, 55L, 80L))
    )
  )
  spend_meta <- round(
    pmax(5000, 11800 * season * trend * exp(rnorm(n, 0, 0.14)))
  )

  # TikTok ramps from a late-Q1 2023 launch. Weeks 1–2 are true zeros (NA in the export).
  tiktok_ramp <- pmin(1, pmax(0, (t - 12) / 40))
  spend_tiktok <- round(
    pmax(0, (1800 + 8200 * tiktok_ramp) * (0.92 + 0.08 * season) * exp(rnorm(n, 0, 0.18)))
  )
  spend_tiktok[1:2] <- 0

  spend_amazon <- round(
    pmax(3500, 7200 * season * trend * exp(rnorm(n, 0, 0.10)))
  )
  # Extra Amazon variation in mid-July (marketplace event weeks).
  amazon_event <- as.numeric(week %in% as.Date(c("2023-07-10", "2024-07-15")))
  spend_amazon <- round(spend_amazon * (1 + 0.55 * amazon_event))

  promo_flag <- as.integer(week %in% as.Date(c(
    "2023-07-03",
    "2023-11-20",
    "2023-11-27",
    "2024-03-18",
    "2024-07-01",
    "2024-11-25",
    "2024-12-02"
  )))

  spend_google <- round(spend_google * (1 + 0.32 * promo_flag))
  spend_meta <- round(spend_meta * (1 + 0.48 * promo_flag))
  spend_amazon <- round(spend_amazon * (1 + 0.22 * promo_flag))

  ads_g <- geometric_adstock(spend_google, 0.50)
  ads_m <- geometric_adstock(spend_meta, 0.50)
  ads_tt <- geometric_adstock(spend_tiktok, 0.45)
  ads_amz <- geometric_adstock(spend_amazon, 0.40)

  cash_sales <- 78000 +
    1.55 * ads_g +
    2.05 * ads_m +
    0.32 * ads_tt +
    0.88 * ads_amz +
    14000 * promo_flag +
    rnorm(n, mean = 0, sd = 4500)

  aov <- 68
  true_orders <- cash_sales / aov

  # DOUBLE-COUNT: Google and Meta both claim overlapping cash. Claim rates sum > 1.
  g_rate <- 0.52 + 0.06 * sin(2 * pi * t / 52) + 0.10 * promo_flag
  m_rate <- 0.48 + 0.12 * promo_flag + 0.06 * as.numeric(t > 52)
  tt_rate <- 0.09 + 0.10 * tiktok_ramp
  amz_rate <- 0.20 + 0.04 * amazon_event

  # Attribution-window shock so claimed conversions drift off cash.
  attr_shock <- as.numeric(t %in% 40:42)

  g_claim <- true_orders * pmax(0.08, g_rate) * exp(rnorm(n, 0, 0.07))
  m_claim <- true_orders * pmax(0.08, m_rate) * exp(rnorm(n, 0, 0.09)) * (1 + 0.35 * attr_shock)
  tt_claim <- true_orders * pmax(0.02, tt_rate) * exp(rnorm(n, 0, 0.12))
  amz_claim <- true_orders * pmax(0.05, amz_rate) * exp(rnorm(n, 0, 0.08))

  platform_reported_conversions <- pmax(
    0,
    round(g_claim + m_claim + tt_claim + amz_claim + rnorm(n, 0, 280))
  )

  spend_tiktok_export <- spend_tiktok
  spend_tiktok_export[1:2] <- NA_real_
  platform_export <- platform_reported_conversions
  platform_export[1] <- NA_real_

  out <- tibble::tibble(
    week = week,
    spend_google = as.numeric(spend_google),
    spend_meta = as.numeric(spend_meta),
    spend_tiktok = as.numeric(spend_tiktok_export),
    spend_amazon = as.numeric(spend_amazon),
    promo_flag = as.integer(promo_flag),
    cash_sales = as.numeric(cash_sales),
    platform_reported_conversions = as.numeric(platform_export)
  )

  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  readr::write_csv(out, path)
  invisible(out)
}
