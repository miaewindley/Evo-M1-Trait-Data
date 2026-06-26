# Smaers_etal_2011_compare_to_public_tsv.R
#
# Checking step. UNLIKE the Stephan-team papers (where we audit against the curated
# master CSV), here we audit the snapshot against the DOI-coded TSVs that already
# existed in the Public folder before this project began (they were "prepared
# elsewhere"). Matched by Individual; values compared by position (the pre-existing
# TSV headers are a collapsed multi-row header). Run from comparison/.
#
# Inputs : ../Smaers_etal_2011_SupplementaryTable1_snapshot.csv ; 10.1159%2F000323671_SupplementaryTable1.tsv
#          ../Smaers_etal_2011_SupplementaryTable2_snapshot.csv ; 10.1159%2F000323671_SupplementaryTable2.tsv
# Outputs: Smaers_etal_2011_SupplementaryTable1_comparison_report_from_R.csv (+ _mismatches)
#          Smaers_etal_2011_SupplementaryTable2_comparison_report_from_R.csv (+ _mismatches)
#
# RESULT (recorded): Suppl. Table 1 = 26/26 individuals identical to the pre-existing
# public TSV. Suppl. Table 2 = 19/26 MISMATCH: the pre-existing public ST2 TSV is
# corrupted (values rounded to integers, and some decimal points dropped, e.g.
# Homo 5694 "19.25" -> "1925"). The snapshot (from the Adobe export) is correct, and
# the __Public ST2 TSV has been regenerated from it.

suppressPackageStartupMessages({ library(readr); library(dplyr); library(stringr); library(tidyr) })
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())
  if (interactive() && requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  setwd("/Users/crossmodal/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/_setwd_backup/Smaers_etal_2011/comparison")
}
num <- function(x) suppressWarnings(as.numeric(gsub(",", "", as.character(x))))

audit <- function(snapshot, pretsv, nval, outbase) {
  snap <- read_csv(snapshot, show_col_types = FALSE)
  pre  <- read_tsv(pretsv, col_names = FALSE, skip = 1, show_col_types = FALSE)  # skip garbled header; read by position
  pre  <- pre %>% rename(Individual = 1)
  snap <- snap %>% mutate(Individual = as.character(.[[1]]))
  # Compare row-by-row (matched on Individual). Avoid rowwise()/cur_data() (deprecated in
  # dplyr 1.1.0 and no longer coercible via as.numeric here), which silently NA-ed every
  # value and reported all rows as MISMATCH.
  status <- vapply(seq_len(nrow(snap)), function(i) {
    pv <- pre[pre$Individual == snap$Individual[i], , drop = FALSE]
    if (nrow(pv) == 0) return("snapshot_only_not_in_pretsv")
    a <- num(unlist(snap[i, 2:(1 + nval)])); b <- num(unlist(pv[1, 2:(1 + nval)]))
    if (all(mapply(function(x, y) isTRUE(abs(x - y) <= 1e-6), a, b))) "matched" else "MISMATCH"
  }, character(1))
  rep <- snap %>% mutate(status = status)
  write_csv(rep, paste0(outbase, "_comparison_report_from_R.csv"))
  write_csv(filter(rep, status != "matched"), paste0(outbase, "_comparison_mismatches_from_R.csv"))
  message(outbase, ": matched ", sum(rep$status == "matched"), " | mismatch ", sum(rep$status != "matched"))
}
audit("../Smaers_etal_2011_SupplementaryTable1_snapshot.csv", "10.1159%2F000323671_SupplementaryTable1.tsv", 5, "Smaers_etal_2011_SupplementaryTable1")
audit("../Smaers_etal_2011_SupplementaryTable2_snapshot.csv", "10.1159%2F000323671_SupplementaryTable2.tsv", 4, "Smaers_etal_2011_SupplementaryTable2")
