#!/usr/bin/env Rscript
# SAMPLE twin of plot_intraday.py. Optional until R exists.
# Reads out/intraday_sample.csv; base graphics only (no tidyverse required).

this_dir <- (function() {
  args <- commandArgs(trailingOnly = FALSE)
  hit <- grep("^--file=", args, value = TRUE)
  if (length(hit) == 1) {
    return(dirname(normalizePath(sub("^--file=", "", hit))))
  }
  getwd()
})()
root <- normalizePath(file.path(this_dir, ".."))
csv_path <- file.path(root, "out", "intraday_sample.csv")
if (!file.exists(csv_path)) {
  stop("Missing ", csv_path, " — run generate_intraday.py first.")
}

dat <- read.csv(csv_path, stringsAsFactors = FALSE)
be <- dat$break_even_mer[1]
png_path <- file.path(root, "out", "SAMPLE_intraday_mer_cut_r.png")

png(png_path, width = 1050, height = 740)
par(mfrow = c(2, 1), mar = c(4, 4, 3, 1))
plot(
  dat$hour, dat$spend_usd, type = "h", lwd = 8, col = "#93c5fd",
  xlab = "", ylab = "USD (SAMPLE)",
  main = "SAMPLE: hourly spend vs cash-proxy — one day (R twin)"
)
lines(dat$hour, dat$cash_proxy_usd, col = "#1d4ed8", lwd = 2)
rect(10.5, par("usr")[3], 13.5, par("usr")[4], col = rgb(254 / 255, 202 / 255, 202 / 255, 0.45), border = NA)
legend("topleft", c("Spend", "Cash-proxy"), col = c("#93c5fd", "#1d4ed8"), lwd = c(8, 2), bty = "n")

plot(
  dat$hour, dat$mer, type = "b", col = "#1d4ed8", lwd = 2,
  xlab = "Hour", ylab = "Cash MER", xaxt = "n",
  main = "SAMPLE: 11:00, MER below break-even for 3 hours → cut."
)
axis(1, at = dat$hour, labels = dat$hour_label, las = 2, cex.axis = 0.7)
abline(h = be, col = "#ea580c", lty = 2, lwd = 2)
rect(10.5, par("usr")[3], 13.5, par("usr")[4], col = rgb(254 / 255, 202 / 255, 202 / 255, 0.45), border = NA)
text(11, min(dat$mer) + 0.15, "11:00, MER below break-even for 3 hours → cut.", col = "#991b1b", adj = 0, cex = 0.85)
dev.off()
message("Wrote ", png_path)
