# SAMPLE: geometric adstock. Not Recast's Bayesian MMM. Not Robyn.
# s[1] = x[1]
# s[t] = x[t] + theta * s[t - 1]

geometric_adstock <- function(x, theta) {
  if (!is.numeric(x)) {
    stop("geometric_adstock(): x must be numeric.")
  }
  if (length(theta) != 1L || is.na(theta) || theta < 0 || theta >= 1) {
    stop("geometric_adstock(): theta must be in [0, 1).")
  }
  n <- length(x)
  s <- rep(NA_real_, n)
  if (n == 0L) {
    return(s)
  }
  s[1] <- x[1]
  if (n > 1L) {
    for (t in 2:n) {
      s[t] <- x[t] + theta * s[t - 1]
    }
  }
  s
}
