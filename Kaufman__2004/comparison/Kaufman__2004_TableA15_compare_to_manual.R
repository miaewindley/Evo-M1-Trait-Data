# Kaufman__2004_TableA15_compare_to_manual.R
#
# Checking (QA), analogous to the other papers' comparison/ scripts. Audits the
# Claude-derived Table A15 build (../Kaufman__2004_TableA15.csv, produced by
# ../Kaufman__2004_TableA15.R from the frozen snapshot) against the manually
# compiled tables Alexandra added to this folder. Nothing is merged across papers.
#
# Manual tables (in "Kaufman data added to compilation/"):
#   Kaufman_energetics_weights.csv                         one row per species, both weightings
#   Kaufman glucose oxygen blood flow/wholebrain_Kaufman2004.csv   Whole Brain, all measures
#   Kaufman glucose oxygen blood flow/partsbrain_Kaufman2004.csv   Cortex + 13 regions
# These wide manual tables are reshaped to long HERE, for comparison only (per the
# request: combined/moved tables live in comparison/ and are amended only to compare).
#
# Outputs (into this comparison/ folder):
#   Kaufman__2004_TableA15_comparison_report.csv       every built vs manual cell
#   Kaufman__2004_TableA15_comparison_mismatches.csv   only mismatches / one-sided cells

suppressPackageStartupMessages({ library(readr); library(dplyr); library(tidyr); library(stringr) })

## ---- paths: self-contained (Rscript or RStudio) ----
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
added <- "Kaufman data added to compilation"
gobf  <- file.path(added, "Kaufman glucose oxygen blood flow")

num <- function(x) suppressWarnings(as.numeric(gsub(",", "", as.character(x))))
canon_measure <- function(m) ifelse(m %in% c("CMR02", "CMRQ2"), "CMRO2", m)
canon_stat <- function(s) dplyr::recode(s,
  "Std. Deviation" = "SD", "Std..Deviation" = "SD", "CV_unbiased" = "CVstar", .default = s)

## ---- BUILT table (the thing under test) ----
built <- read_csv("../Kaufman__2004_TableA15.csv", show_col_types = FALSE,
                  col_types = cols(.default = col_character())) %>%
  transmute(genus = species, weighting = tolower(weighting),
            region, measure = canon_measure(measure),
            N = num(N), Mean = num(Mean), SD = num(SD), CV = num(CV), CVstar = num(CVstar)) %>%
  pivot_longer(c(N, Mean, SD, CV, CVstar), names_to = "stat", values_to = "built")

## ---- MANUAL wide tables -> long (comparison-only reshape) ----
read_wide <- function(path, wcol) {
  read_csv(path, show_col_types = FALSE, col_types = cols(.default = col_character())) %>%
    rename(weighting = all_of(wcol)) %>%
    select(-any_of(c("Speciesweight", "Kaufman.Species"))) %>%
    pivot_longer(-c(Species, weighting), names_to = "col", values_to = "value") %>%
    mutate(
      stat_raw = str_match(col, "[ .](N|Mean|Std\\.?\\.?\\s?Deviation|CV_unbiased|CV)$")[, 2],
      rest     = str_remove(col, "[ .](N|Mean|Std\\.?\\.?\\s?Deviation|CV_unbiased|CV)$"),
      measure  = str_match(rest, "[ .](CMRgl|CMRO2|CMR02|CBF)$")[, 2],
      region   = str_squish(str_replace_all(str_remove(rest, "[ .](CMRgl|CMRO2|CMR02|CBF)$"), "\\.", " "))
    ) %>%
    filter(!is.na(stat_raw), !is.na(measure)) %>%
    transmute(genus = Species, weighting = tolower(str_squish(weighting)), region,
              measure = canon_measure(measure), stat = canon_stat(stat_raw), manual = num(value))
}
manual <- bind_rows(
  read_wide(file.path(gobf, "wholebrain_Kaufman2004.csv"), "weight"),
  read_wide(file.path(gobf, "partsbrain_Kaufman2004.csv"), "Weight")
) %>% distinct()

keys <- c("genus", "weighting", "region", "measure", "stat")
report <- full_join(built, manual, by = keys) %>%
  mutate(
    real_built  = !is.na(built), real_manual = !is.na(manual),
    tol = ifelse(stat == "N", 0, 0.011),
    status = case_when(
      real_built & real_manual & abs(built - manual) <= tol ~ "match",
      real_built & real_manual                              ~ "MISMATCH",
      real_built                                            ~ "built_only",
      real_manual                                           ~ "manual_only",
      TRUE                                                  ~ "both_absent"),
    diff = ifelse(real_built & real_manual, round(built - manual, 4), NA_real_)) %>%
  arrange(genus, region, measure, weighting, stat) %>%
  relocate(status, genus, weighting, region, measure, stat, built, manual, diff)

write_csv(report, "Kaufman__2004_TableA15_comparison_report.csv")
write_csv(filter(report, !status %in% c("match", "both_absent")),
          "Kaufman__2004_TableA15_comparison_mismatches.csv")

message("compared: ", sum(report$status %in% c("match", "MISMATCH")),
        " | matches: ", sum(report$status == "match"),
        " | MISMATCH: ", sum(report$status == "MISMATCH"),
        " | built_only: ", sum(report$status == "built_only"),
        " | manual_only: ", sum(report$status == "manual_only"))
