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
