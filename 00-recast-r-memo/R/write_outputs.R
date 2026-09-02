# SAMPLE writers: priors, geo design, CMO memo, PNGs.
# Memo numbers come from broom::tidy / glance, not from the DGP.

channel_label <- function(term) {
  labels <- c(
    ads_google = "Google",
    ads_meta = "Meta",
    ads_tiktok = "TikTok",
    ads_amazon = "Amazon",
    promo_flag = "Promo week"
  )
  unname(ifelse(term %in% names(labels), labels[term], term))
}

fmt_usd <- function(x, digits = 2) {
  vapply(x, function(z) {
    if (is.na(z)) {
      return("NA")
    }
    sign <- if (z < 0) "-" else ""
    paste0(
      sign, "$",
      format(round(abs(z), digits), nsmall = digits, big.mark = ",", scientific = FALSE, trim = TRUE)
    )
  }, character(1))
}

fmt_pct <- function(x, digits = 1) {
  sprintf(paste0("%.", digits, "f%%"), 100 * x)
}

count_words <- function(lines) {
  txt <- paste(lines, collapse = " ")
  txt <- gsub("```", " ", txt)
  parts <- strsplit(trimws(txt), "\\s+")[[1]]
  length(parts[nzchar(parts)])
}

vif_from_lm <- function(model) {
  mm <- stats::model.matrix(model)
  keep <- colnames(mm) != "(Intercept)"
  mm <- mm[, keep, drop = FALSE]
  if (ncol(mm) == 0L) {
    return(tibble::tibble(term = character(), vif = numeric()))
  }
  vifs <- vapply(seq_len(ncol(mm)), function(j) {
    y <- as.numeric(mm[, j])
    other <- mm[, -j, drop = FALSE]
    if (ncol(other) == 0L) {
      return(1)
    }
    dat <- as.data.frame(other, stringsAsFactors = FALSE)
    dat[] <- lapply(dat, as.numeric)
    names(dat) <- paste0("x", seq_len(ncol(dat)))
    dat$y <- y
    fit_aux <- stats::lm(y ~ ., data = dat)
    r2 <- summary(fit_aux)$r.squared
    if (is.na(r2) || r2 >= (1 - 1e-12)) {
      return(Inf)
    }
    1 / (1 - r2)
  }, numeric(1))
  tibble::tibble(term = colnames(mm), vif = as.numeric(vifs))
}

write_priors <- function(path) {
  lines <- c(
    "# SAMPLE: channel priors (operator experience, not this dataset)",
    "",
    "These are **PRIORS** — beliefs a media operator would write down *before* looking at the OLS fit in `tidy.csv`. They are not posteriors, not last-click ROAS, and not the data-generating process in the README.",
    "",
    "Recast onboarding asks you to set priors with the client, then interpret the model, then plan a test. This file is that first step.",
    "",
    "## Google (Search + Shopping mix)",
    "",
    "- **PRIOR (return):** cash per adstocked dollar somewhere in **$1.20–$2.40**. Branded query is partly stolen from demand that would have arrived anyway; non-brand and Shopping are closer to capture.",
    "- **PRIOR (carryover):** moderate. Most of the click-to-cash happens inside a week; a leftover halo of about half a week is plausible (geometric θ near 0.4–0.6).",
    "- **PRIOR (saturation):** already a large share of paid. Extra dollars likely diminish faster than Meta prospecting.",
    "- **Source:** operator experience on paid search. **Not this SAMPLE regression.**",
    "",
    "## Meta",
    "",
    "- **PRIOR (return):** cash per adstocked dollar **$1.60–$2.80** if creative is working. Last-click under-credits prospecting and over-credits retargeting; the net in cash is usually better than the ads manager in an iOS-attribution world.",
    "- **PRIOR (carryover):** longer than Google. View-through and delayed branded search show up in later weeks (θ prior 0.45–0.65).",
    "- **PRIOR (saturation):** still room if frequency is not already high; do not scale retargeting pools as if they were net-new.",
    "- **Source:** operator experience. **Not this SAMPLE regression.**",
    "",
    "## TikTok",
    "",
    "- **PRIOR (return):** weak same-week cash. **$0.15–$0.90** per adstocked dollar is the honest range. Upper-funnel education, not a demand-capture channel.",
    "- **PRIOR (carryover):** medium (θ prior 0.35–0.55) but the *level* of cash is the uncertainty, not the decay.",
    "- **PRIOR (saturation):** unknown until the channel is out of “learning.” High uncertainty is the prior.",
    "- **Source:** operator experience. **Not this SAMPLE regression.** This is the channel I would geo-test first if the model interval is wide.",
    "",
    "## Amazon Ads",
    "",
    "- **PRIOR (return):** closer to intent capture than TikTok. **$0.60–$1.40** per adstocked dollar. Competes with organic marketplace rank; some spend is defensive.",
    "- **PRIOR (carryover):** shorter than Meta (θ prior 0.30–0.50).",
    "- **PRIOR (saturation):** share-of-voice on the SKU matters more than a national reach curve.",
    "- **Source:** operator experience. **Not this SAMPLE regression.**",
    "",
    "## Promo weeks",
    "",
    "- **PRIOR:** sitewide sale / BFCM-ish weeks move cash a lot. Always include the flag so paid channels do not steal promo.",
    "- **Source:** operator experience. **Not this SAMPLE regression.**",
    "",
    "## What these priors are for",
    "",
    "If the OLS interval lands inside the prior, we still do not scale the weakest channel from the regression alone. If it lands outside, we do not “update” by staring at last-click. We write the disagreement down and test cash in geos.",
    ""
  )
  writeLines(lines, path)
  invisible(lines)
}

build_channel_plan <- function(spend_tidy) {
  st <- spend_tidy %>%
    dplyr::mutate(
      channel = vapply(term, channel_label, character(1)),
      ci_width = conf.high - conf.low,
      includes_zero = conf.low <= 0 & conf.high >= 0,
      identified = conf.low > 0
    )
  widest_i <- which.max(st$ci_width)
  widest <- st[widest_i, , drop = FALSE]

  # Widest-CI channel is always frozen for the geo test — never the scale call.
  scale_pool <- st %>% dplyr::filter(.data$identified, .data$term != widest$term)
  scale_row <- if (nrow(scale_pool) > 0) {
    scale_pool %>% dplyr::slice_max(.data$estimate, n = 1, with_ties = FALSE)
  } else {
    NULL
  }

  freeze_terms <- unique(c(widest$term, st$term[st$includes_zero]))
  hold_rows <- st %>%
    dplyr::filter(!.data$term %in% freeze_terms)
  if (!is.null(scale_row) && nrow(scale_row) == 1) {
    hold_rows <- hold_rows %>% dplyr::filter(.data$term != scale_row$term)
  }

  list(
    spend_tidy = st,
    widest = widest,
    scale_row = scale_row,
    hold_rows = hold_rows,
    freeze_rows = st %>% dplyr::filter(.data$term %in% freeze_terms)
  )
}

write_experiment <- function(path, plan, train, theta, glance_fit) {
  w <- plan$widest
  ch <- w$channel
  spend_map <- c(
    ads_google = "spend_google",
    ads_meta = "spend_meta",
    ads_tiktok = "spend_tiktok",
    ads_amazon = "spend_amazon"
  )
  spend_col <- unname(spend_map[w$term])
  if (is.na(spend_col)) {
    stop("Unknown adstock term for geo design: ", w$term)
  }
  ads_col <- w$term
  mean_spend <- mean(train[[spend_col]], na.rm = TRUE)
  mean_ads <- mean(train[[ads_col]], na.rm = TRUE)
  mean_contrib <- w$estimate * mean_ads

  pause_reason <- if (isTRUE(w$includes_zero)) {
    "The OLS interval includes zero, so the first question is *whether cash moves at all*, not the exact coefficient. A pause is the cleaner design."
  } else {
    "The interval is the widest of the four paid channels. A pause asks whether the channel is incremental in cash; we are not trying to recover the OLS point estimate in four weeks."
  }

  lines <- c(
    "# SAMPLE: 4-week GeoLift design (not a result)",
    "",
    "This folder does **not** run GeoLift. This is the experiment we would take to a client after the OLS + adstock pass, matching Recast’s loop: priors → interpret → **validate**.",
    "",
    sprintf("**Channel under test:** %s (widest 95%% CI on adstocked spend).", ch),
    sprintf(
      "**OLS we are validating:** %s cash per adstocked dollar (95%% CI %s to %s). CI width %s.",
      fmt_usd(w$estimate), fmt_usd(w$conf.low), fmt_usd(w$conf.high), fmt_usd(w$ci_width)
    ),
    sprintf("**Adstock used in that fit:** geometric θ = %s (shared across channels; selected on holdout RMSE).", format(theta)),
    sprintf(
      "**Training scale:** mean weekly %s spend %s; mean adstocked %s; OLS-implied mean weekly cash contribution %s (not a causal ATT).",
      ch, fmt_usd(mean_spend, 0), fmt_usd(mean_ads, 0), fmt_usd(mean_contrib, 0)
    ),
    sprintf("**In-sample R² (train):** %s. This is not the success metric of the test.", format(round(glance_fit$r.squared, 3))),
    "",
    "## Hypothesis",
    "",
    sprintf(
      "If %s is incremental in cash, turning it off in treatment markets for four weeks will reduce cash sales relative to a synthetic control. %s",
      ch, pause_reason
    ),
    "",
    "## Treatment",
    "",
    sprintf("- **Action:** pause %s (spend → $0) in treatment markets only.", ch),
    "- **What stays fixed:** national creative, site promo calendar, the other three paid channels’ bidding rules, and landing pages.",
    "- **What we refuse:** a national budget change during the test; treating NYC and leaving Newark; using platform-reported conversions as the outcome.",
    "",
    "## Markets (SAMPLE list — mid-size DMAs, not a power run)",
    "",
    "**Treatment (8):** Indianapolis, Kansas City, Nashville, Milwaukee, Oklahoma City, Louisville, Raleigh-Durham, Austin.",
    "",
    "**Donor pool (examples, not exhaustive):** Columbus, Cincinnati, Pittsburgh, Cleveland, St. Louis, Omaha, Des Moines, Tulsa, Birmingham, Memphis, Richmond, Norfolk, Jacksonville, Tampa, Orlando, Grand Rapids, Madison, Boise, Albuquerque, Tucson.",
    "",
    "**Excluded on purpose:** New York, Los Angeles, Chicago, Dallas (too large a share of national cash; one market must not be ~40% of sales). Do not treat a DMA and leave its adjacent DMA in the donor pool (spillover).",
    "",
    "This list is a **design**. Power and market selection belong in the GeoLift package run (sibling folder), not here.",
    "",
    "## Calendar",
    "",
    "- **Pre-period:** 12 weeks of cash-sales matching before launch (synthetic control / augsynth-style).",
    "- **Test window:** four consecutive weeks. SAMPLE dates if we ran it after this panel: **2025-01-06 through 2025-02-02** (weeks starting Monday).",
    "- **Cooldown:** one week after, still no national reallocation, so we can see carryover instead of stuffing spend back in on day 29.",
    "",
    "## KPI and success",
    "",
    "- **Primary KPI:** **cash sales** (settled dollars). Not ROAS, not platform-reported conversions, not blended MER as the test outcome.",
    "- **Guardrails:** % of treatment weeks with true $0 on the tested channel; no simultaneous sitewide promo that was not in the pre-period pattern; donor markets do not receive the leftover budget.",
    "- **Success:** the **95% CI on incremental cash sales (ATT) excludes 0**.",
    "- **Failure / freeze:** CI includes 0. We do **not** scale the channel from the OLS point estimate.",
    "- **If the CI excludes 0 but the ATT is far from the OLS contribution:** believe the geo test for *direction*; do not force the MMM coefficient to match a four-week ATT.",
    "",
    "## Power honesty",
    "",
    "Four weeks is short. Weekly cash is noisy. A 4-week pause in 8 of ~210 DMAs may only detect a large effect. If a proper GeoLift power curve says the MDE is bigger than the OLS-implied lift, we extend the test (or add markets) rather than calling a noisy zero a “disproof.” We still do not scale while that CI includes 0.",
    "",
    "## What this test is not",
    "",
    "- Not a national holdout.",
    "- Not MTA.",
    "- Not Recast’s ~30k-parameter model.",
    "- Not a GeoLift *result* — there is no ATT in this folder.",
    ""
  )
  writeLines(lines, path)
  invisible(lines)
}

write_cmo_memo <- function(path, plan, tidy_fit, glance_fit, vif_tbl, diagnostics) {
  st <- plan$spend_tidy
  promo <- tidy_fit %>% dplyr::filter(.data$term == "promo_flag")
  intercept <- tidy_fit %>% dplyr::filter(.data$term == "(Intercept)")

  coef_line <- function(row) {
    sprintf(
      "%s: %s per adstocked dollar (95%% CI %s to %s)",
      row$channel, fmt_usd(row$estimate), fmt_usd(row$conf.low), fmt_usd(row$conf.high)
    )
  }
  bullets <- vapply(seq_len(nrow(st)), function(i) paste0("- ", coef_line(st[i, ])), character(1))

  vif_spend <- vif_tbl %>% dplyr::filter(.data$term %in% st$term)
  vif_txt <- paste(
    sprintf("%s VIF %.2f", vapply(vif_spend$term, channel_label, character(1)), vif_spend$vif),
    collapse = "; "
  )
  max_vif <- max(vif_spend$vif, na.rm = TRUE)
  vif_note <- if (is.finite(max_vif) && max_vif >= 5) {
    sprintf("Max paid-channel VIF is %.2f. Do not over-interpret a single channel until that collinearity is addressed.", max_vif)
  } else {
    sprintf("Max paid-channel VIF is %.2f — collinearity is not the main story.", max_vif)
  }

  scale_txt <- if (!is.null(plan$scale_row) && nrow(plan$scale_row) == 1) {
    r <- plan$scale_row
    sprintf(
      "**Scale — %s.** 95%% CI is entirely above 0 (%s to %s). Point estimate %s cash per adstocked dollar. Add dollars in steps; do not dump the freeze-channel budget into it.",
      r$channel, fmt_usd(r$conf.low), fmt_usd(r$conf.high), fmt_usd(r$estimate)
    )
  } else {
    "**Scale — none this week.** No identified paid channel besides the geo-test freeze. Do not invent a scale call."
  }

  if (nrow(plan$hold_rows) > 0) {
    hold_names <- paste(plan$hold_rows$channel, collapse = ", ")
    hold_txt <- sprintf(
      "**Hold — %s.** Keep near the training mix (Google %s / Meta %s / TikTok %s / Amazon %s) until the %s geo test is back.",
      hold_names,
      fmt_pct(diagnostics$share_google),
      fmt_pct(diagnostics$share_meta),
      fmt_pct(diagnostics$share_tiktok),
      fmt_pct(diagnostics$share_amazon),
      plan$widest$channel
    )
  } else {
    hold_txt <- sprintf(
      "**Hold — remaining paid.** Do not backfill %s dollars into other channels during the geo test.",
      plan$widest$channel
    )
  }

  freeze <- plan$widest
  freeze_txt <- sprintf(
    "**Do not scale — %s.** Widest interval (%s; %s to %s). Point estimate %s is not a license to scale. Geo design in experiment.md: KPI = cash sales; success = 95%% CI on incremental cash excludes 0.",
    freeze$channel,
    fmt_usd(freeze$ci_width),
    fmt_usd(freeze$conf.low),
    fmt_usd(freeze$conf.high),
    fmt_usd(freeze$estimate)
  )

  promo_txt <- if (nrow(promo) == 1) {
    sprintf(
      "Promo week adds %s cash (95%% CI %s to %s). That is a dummy, not a media ROI. Paid channels do not get credit for BFCM-ish weeks.",
      fmt_usd(promo$estimate, 0), fmt_usd(promo$conf.low, 0), fmt_usd(promo$conf.high, 0)
    )
  } else {
    "Promo week is in the specification so media does not steal sale weeks."
  }

  intercept_txt <- if (nrow(intercept) == 1) {
    sprintf("Baseline (intercept) is %s per week.", fmt_usd(intercept$estimate, 0))
  } else {
    ""
  }

  lines <- c(
    "# SAMPLE: CMO memo — cash vs claimed conversions",
    "",
    "This is **SAMPLE** synthetic data. Not a client. The model is OLS plus geometric adstock — not a ~30k-parameter Bayesian MMM.",
    "",
    "## Why finance should ignore the ads managers",
    "",
    sprintf(
      "Platform-reported conversions and cash sales do not match. Correlation is **%.2f**. Claimed conversions run **%.2f×** implied orders (cash / $68 AOV). Google and Meta both claim overlapping purchases. Missing before impute: TikTok spend %s, platform conversions %s. We modeled **cash sales**.",
      diagnostics$cor_platform_cash,
      diagnostics$claim_inflation,
      fmt_pct(diagnostics$miss_tiktok, 1),
      fmt_pct(diagnostics$miss_platform, 1)
    ),
    "",
    "## What we fit",
    "",
    sprintf(
      "Train weeks 1–91, holdout 92–104. Shared geometric adstock θ = **%s** by holdout RMSE on cash (**%s**; grid 0.3 / 0.5 / 0.7). Train R² = %.3f. %s %s",
      format(diagnostics$theta),
      fmt_usd(diagnostics$holdout_rmse, 0),
      glance_fit$r.squared,
      promo_txt,
      intercept_txt
    ),
    "",
    sprintf(
      "Spend mix on train: Google %s, Meta %s, TikTok %s, Amazon %s.",
      fmt_pct(diagnostics$share_google),
      fmt_pct(diagnostics$share_meta),
      fmt_pct(diagnostics$share_tiktok),
      fmt_pct(diagnostics$share_amazon)
    ),
    "",
    "Cash per **adstocked** dollar (not last-click ROAS):",
    "",
    bullets,
    "",
    vif_note,
    paste0("VIF: ", vif_txt, "."),
    "",
    "## Cut / hold / scale",
    "",
    scale_txt,
    "",
    hold_txt,
    "",
    freeze_txt,
    "",
    "## What we will not do until the geo test",
    "",
    sprintf("We will not reallocate the %s annual plan from this OLS interval.", freeze$channel),
    "We will not treat platform-reported conversions as the geo KPI.",
    "We will not add channel interaction terms and call that incrementality.",
    "We will not change national creative or dump leftover budget into donor markets during the four-week window.",
    "We will not quote last-click ROAS as the decision.",
    "",
    "## Next",
    "",
    "1. Keep `priors.md` as beliefs, separate from this fit.",
    sprintf("2. Run the geo test on **%s** (design in experiment.md).", freeze$channel),
    "3. Change scale / hold / cut only after the cash ATT interval, not after another dashboard export.",
    ""
  )

  n_words <- count_words(lines)
  attr(lines, "word_count") <- n_words
  if (n_words > 800) {
    stop("CMO memo is ", n_words, " words; cap is 800.")
  }
  writeLines(lines, path)
  invisible(lines)
}

write_plots <- function(df, spend_tidy, out_dir) {
  df_plot <- df %>%
    dplyr::mutate(
      total_spend = .data$spend_google + .data$spend_meta + .data$spend_tiktok + .data$spend_amazon,
      implied_orders = .data$cash_sales / 68
    )

  long_ts <- dplyr::bind_rows(
    df_plot %>% dplyr::transmute(week = .data$week, series = "Total paid spend (USD)", value = .data$total_spend),
    df_plot %>% dplyr::transmute(week = .data$week, series = "Cash sales (USD)", value = .data$cash_sales)
  )

  p_spend <- ggplot2::ggplot(long_ts, ggplot2::aes(.data$week, .data$value)) +
    ggplot2::geom_line(linewidth = 0.6, color = "#1f4e79") +
    ggplot2::facet_wrap(~series, scales = "free_y", ncol = 1) +
    ggplot2::labs(
      title = "SAMPLE: weekly paid spend vs cash sales",
      subtitle = "Synthetic 104-week panel. Promo weeks marked in the DGP, not on this chart.",
      x = "Week",
      y = NULL,
      caption = "SAMPLE synthetic data. Not a client. Not last-click ROAS."
    ) +
    ggplot2::theme_minimal(base_size = 12)

  ggplot2::ggsave(
    filename = file.path(out_dir, "spend_vs_cash.png"),
    plot = p_spend,
    width = 10,
    height = 6.2,
    dpi = 120
  )

  claimed_long <- dplyr::bind_rows(
    df_plot %>% dplyr::transmute(
      week = .data$week,
      series = "Cash / $68 AOV (implied orders)",
      value = .data$implied_orders
    ),
    df_plot %>% dplyr::transmute(
      week = .data$week,
      series = "Platform-reported conversions",
      value = .data$platform_reported_conversions
    )
  )

  p_claim <- ggplot2::ggplot(claimed_long, ggplot2::aes(.data$week, .data$value, color = .data$series)) +
    ggplot2::geom_line(linewidth = 0.65) +
    ggplot2::labs(
      title = "SAMPLE: claimed conversions vs cash implied orders",
      subtitle = "Google and Meta double-count overlapping purchases. Do not fit on claimed conversions.",
      x = "Week",
      y = "Weekly orders",
      color = NULL,
      caption = "SAMPLE synthetic data. Not a client."
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(legend.position = "bottom")

  ggplot2::ggsave(
    filename = file.path(out_dir, "claimed_vs_cash.png"),
    plot = p_claim,
    width = 10,
    height = 5.8,
    dpi = 120
  )

  forest <- spend_tidy %>%
    dplyr::mutate(channel = vapply(term, channel_label, character(1)))

  p_forest <- ggplot2::ggplot(
    forest,
    ggplot2::aes(x = .data$estimate, y = stats::reorder(.data$channel, .data$estimate))
  ) +
    ggplot2::geom_vline(xintercept = 0, linetype = 2, color = "gray40") +
    ggplot2::geom_pointrange(
      ggplot2::aes(xmin = .data$conf.low, xmax = .data$conf.high),
      color = "#1f4e79"
    ) +
    ggplot2::labs(
      title = "SAMPLE: cash per adstocked dollar (95% CI)",
      subtitle = "OLS on cash sales. Promo dummy omitted (different units).",
      x = "USD cash / USD adstocked spend",
      y = NULL,
      caption = "SAMPLE synthetic data. Not a client. Not Recast posteriors."
    ) +
    ggplot2::theme_minimal(base_size = 12)

  ggplot2::ggsave(
    filename = file.path(out_dir, "coefficients.png"),
    plot = p_forest,
    width = 9,
    height = 4.8,
    dpi = 120
  )

  invisible(TRUE)
}
