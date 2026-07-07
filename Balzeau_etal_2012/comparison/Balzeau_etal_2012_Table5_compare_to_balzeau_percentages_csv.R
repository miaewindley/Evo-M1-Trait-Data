## Balzeau_etal_2012 Table 5 — QA / checking step
## Audit the frozen snapshot (../Balzeau_etal_2012_Table5_snapshot.csv) against
## the pre-existing curated table (comparison/balzeau_percentages.csv). Requires
## 0 value mismatches on n / Mean / V* across 5 samples x 3 lobes (45 values).
## Run from the comparison/ folder.

suppressPackageStartupMessages({ library(stringr) })

.sp <- local({
  a <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  if (length(a)) return(normalizePath(sub("^--file=", "", a[1])))
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    p <- rstudioapi::getSourceEditorContext()$path
    if (!nzchar(p)) p <- rstudioapi::getActiveDocumentContext()$path
    if (nzchar(p)) return(normalizePath(p))
  }
  stop("Run with Rscript file.R, or open in RStudio and click Source (save first).", call. = FALSE)
})
setwd(dirname(.sp))

snapshot_file   <- "../Balzeau_etal_2012_Table5_snapshot.csv"
curated_file    <- "balzeau_percentages.csv"
out_report      <- "Balzeau_etal_2012_Table5_comparison_report_from_R.csv"
out_mismatches  <- "Balzeau_etal_2012_Table5_comparison_mismatches_from_R.csv"

samples <- c("Homo habilis s.l.", "African and Georgian Homo erectus s.l.",
             "Asian Homo erectus", "Neandertals s.l.", "AMH")
lobes   <- c("Frontal lobes", "Parieto-temporal lobes", "Occipital lobes")

snap_raw <- read.csv(snapshot_file, header = FALSE, colClasses = "character",
                     check.names = FALSE, na.strings = c("", "NA"))
snap <- list()
for (r in 4:6) {
  lobe <- trimws(snap_raw[r, 1])
  for (s in seq_along(samples)) {
    off <- 1 + (s - 1) * 3
    snap[[paste(lobe, samples[s])]] <- as.numeric(snap_raw[r, (off + 1):(off + 3)])
  }
}

txt <- paste(readLines(curated_file, warn = FALSE), collapse = " ")
cur <- list()
for (lobe in lobes) {
  m <- str_match(txt, paste0(str_replace_all(lobe, "([.^$*+?()\\[\\]{}|\\\\])", "\\\\\\1"),
                             "\\s*,\\s*((?:[-0-9.]+\\s*,?\\s*){15})"))[, 2]
  nums <- as.numeric(str_split(str_trim(str_replace(m, ",\\s*$", "")), "\\s*,\\s*")[[1]])
  for (s in seq_along(samples)) {
    off <- (s - 1) * 3
    cur[[paste(lobe, samples[s])]] <- nums[(off + 1):(off + 3)]
  }
}

fields <- c("n", "Mean", "V*")
rows <- list(); nmis <- 0
for (lobe in lobes) for (s in samples) {
  key <- paste(lobe, s)
  for (j in seq_along(fields)) {
    sv <- snap[[key]][j]; cv <- cur[[key]][j]
    ok <- isTRUE(abs(sv - cv) <= 1e-9)
    if (!ok) nmis <- nmis + 1
    rows[[length(rows) + 1]] <- data.frame(Structure = lobe, Sample = s, field = fields[j],
                                           snapshot = sv, curated = cv, match = ok,
                                           stringsAsFactors = FALSE)
  }
}
report <- do.call(rbind, rows)
write.csv(report, out_report, row.names = FALSE)
write.csv(report[!report$match, , drop = FALSE], out_mismatches, row.names = FALSE)
message("Checked ", nrow(report), " values; mismatches: ", nmis)
