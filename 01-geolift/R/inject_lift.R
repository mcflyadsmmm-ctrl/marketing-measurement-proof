# SAMPLE helper. Multiplies cash sales (package column Y) in treated geos
# for a closed time window. Does not invent markets.

inject_relative_lift <- function(data,
                                 locations,
                                 treatment_start_time,
                                 treatment_end_time,
                                 lift = 0.08,
                                 Y_id = "Y",
                                 location_id = "location",
                                 time_id = "time") {
  if (lift <= -1) {
    stop("lift must be greater than -1.")
  }
  if (treatment_end_time < treatment_start_time) {
    stop("treatment_end_time must be >= treatment_start_time.")
  }
  locations <- unique(tolower(trimws(locations)))
  out <- data
  loc <- tolower(as.character(out[[location_id]]))
  t <- as.numeric(out[[time_id]])
  mask <- loc %in% locations &
    t >= treatment_start_time &
    t <= treatment_end_time
  n <- sum(mask)
  if (n == 0) {
    stop("inject_relative_lift: no rows matched locations x window.")
  }
  out[[Y_id]][mask] <- out[[Y_id]][mask] * (1 + lift)
  attr(out, "n_injected") <- n
  attr(out, "lift") <- lift
  attr(out, "locations") <- locations
  attr(out, "treatment_start_time") <- treatment_start_time
  attr(out, "treatment_end_time") <- treatment_end_time
  out
}

split_market_string <- function(location_field) {
  raw <- as.character(location_field)[[1]]
  locs <- trimws(unlist(strsplit(raw, ",", fixed = TRUE)))
  unique(tolower(locs[nzchar(locs)]))
}

# augsynth 0.2.0 treated_table() does t(df[trt_index, ]) and dies when
# length(trt_index) > 1 (Yobs length = n_treated * T). GeoLift 2.7.5 still
# calls summary(augsynth) before it colMeans the treated series. Collapse
# the treatment cell to one unit so the fit can return ATT.
collapse_treatment_cell <- function(data,
                                    locations,
                                    cell_name = "treatment_cell",
                                    Y_id = "Y",
                                    location_id = "location",
                                    time_id = "time") {
  locations <- unique(tolower(trimws(locations)))
  loc <- tolower(as.character(data[[location_id]]))
  treated <- data[loc %in% locations, , drop = FALSE]
  donors <- data[!loc %in% locations, , drop = FALSE]
  if (!nrow(treated)) {
    stop("collapse_treatment_cell: no treated rows.")
  }
  agg <- stats::aggregate(
    treated[[Y_id]],
    by = list(time = treated[[time_id]]),
    FUN = sum,
    na.rm = TRUE
  )
  names(agg) <- c(time_id, Y_id)
  cell <- agg
  cell[[location_id]] <- cell_name
  extra <- setdiff(names(data), c(time_id, Y_id, location_id))
  for (col in extra) {
    cell[[col]] <- if (is.numeric(data[[col]])) {
      0
    } else {
      NA
    }
  }
  cell <- cell[, names(data), drop = FALSE]
  rbind(donors, cell)
}
