# Baron_etal_1983_Table1_compare_to_Baron_1983_csv.R
#
# Purpose
#   Checking step (self-contained in this comparison/ folder). Audit the
#   formatted CSV (Baron_1983.csv) against the faithful snapshot of Baron et al.
#   1983 Table 1. Rows are matched by Baron code, then two things are checked:
#     1. measured values - n and MOB volume (numeric)
#     2. faithful name    - snapshot original vs the CSV's Species_Baron1983
#                           (a difference here is a transcription typo)
#   No taxonomy/crosswalk is involved here.
#
# Inputs (run this script from the comparison/ folder)
#   ../Baron_etal_1983_Table1_snapshot.xlsx   sheet: Table1_snapshot
#   Baron_1983.csv                            formatted comparison table (same folder)
#
# Outputs (written here in comparison/)
#   Baron_etal_1983_Table1_comparison_report_from_R.csv      every row, both checks
#   Baron_etal_1983_Table1_comparison_mismatches_from_R.csv  rows needing attention
#
# Encoding fix retained: Baron_1983.csv is read with latin1 so the stray 0xCA
# byte in "Scutisorex somereni" cannot silently truncate the read.

suppressPackageStartupMessages({
  library(readxl)
  library(readr)
  library(dplyr)
  library(tidyr)
  library(stringr)
})

# Run from this script's own folder (RStudio), so the relative paths resolve.
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  if (interactive() && requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  setwd("/Users/crossmodal/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/_setwd_backup/Baron_etal_1983/comparison")
}
}

snapshot_file     <- "../Baron_etal_1983_Table1_snapshot.xlsx"
snapshot_sheet    <- "Table1_snapshot"
comparison_file   <- "Baron_1983.csv"
output_detail     <- "Baron_etal_1983_Table1_comparison_report_from_R.csv"
output_mismatches <- "Baron_etal_1983_Table1_comparison_mismatches_from_R.csv"

# ---- helpers ---------------------------------------------------------------

read_snapshot <- function(path, sheet) {
  raw <- read_excel(path, sheet = sheet, col_names = FALSE, col_types = "text", na = c(""))
  header <- as.character(unlist(raw[2, ], use.names = FALSE))
  dat <- raw[-c(1, 2), , drop = FALSE]
  names(dat) <- header
  dat
}
# Baron_1983.csv: latin1 so every byte is read (avoids 0xCA truncation).
read_baron_csv <- function(path) {
  read_csv(path, locale = locale(encoding = "latin1"),
           col_types = cols(.default = col_character()), na = c(""))
}
norm_code   <- function(x) suppressWarnings(as.integer(str_remove_all(as.character(x), "\\D")))
parse_value <- function(x) parse_number(x, na = c("", "-", "NA", "n.a.", "__"))
norm_label  <- function(x) str_squish(tolower(str_remove_all(str_remove_all(x, "[0-9]+"), "\\.")))
num_match   <- function(a, b, tol = 1e-8) {
  (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & abs(a - b) <= tol)
}

# ---- read both sources -----------------------------------------------------

snap_species <- read_snapshot(snapshot_file, snapshot_sheet) %>%
  rename(code_raw = `code number of species`, species_raw = `species name`) %>%
  filter(!is.na(code_raw) & str_detect(code_raw, "^[0-9]{4}$")) %>%
  transmute(
    code_join           = norm_code(code_raw),
    code_snapshot       = code_raw,
    species_snapshot    = species_raw,
    n_snapshot          = n,
    n_snapshot_num      = as.integer(parse_value(n)),
    volume_snapshot     = `volume in mm3`,
    volume_snapshot_num = parse_value(`volume in mm3`),
    sp_snapshot_norm    = norm_label(species_raw)
  )

comparison <- read_baron_csv(comparison_file) %>%
  filter(!str_detect(replace_na(Species, ""), "^AAAA_")) %>%
  filter(!is.na(Bulbus_olfactorius_1983)) %>%
  transmute(
    code_join             = norm_code(code_Baron1983),
    code_csv              = code_Baron1983,
    species_csv_baron1983 = Species_Baron1983,
    n_csv                 = Number_of_individuals_Bulbus_olfactorius,
    n_csv_num             = as.integer(parse_value(Number_of_individuals_Bulbus_olfactorius)),
    volume_csv            = Bulbus_olfactorius_1983,
    volume_csv_num        = parse_value(Bulbus_olfactorius_1983),
    sp_csv_baron_norm     = norm_label(Species_Baron1983)
  )

# ---- match by code and run the two checks ----------------------------------

report <- snap_species %>%
  full_join(comparison, by = "code_join") %>%
  mutate(
    status = case_when(
      is.na(code_snapshot) ~ "csv_value_row_missing_from_snapshot",
      is.na(code_csv)      ~ "snapshot_row_missing_from_csv",
      TRUE                 ~ "matched_by_code"
    ),
    n_match      = num_match(n_snapshot_num, n_csv_num),
    volume_match = num_match(volume_snapshot_num, volume_csv_num),
    faithful_name_match = if_else(status == "matched_by_code",
                                  sp_snapshot_norm == sp_csv_baron_norm, NA)
  ) %>%
  rowwise() %>%
  mutate(
    flag_reason = {
      r <- character(0)
      if (status != "matched_by_code")  r <- c(r, status)
      if (isFALSE(n_match))             r <- c(r, "n differs")
      if (isFALSE(volume_match))        r <- c(r, "volume differs")
      if (isFALSE(faithful_name_match)) r <- c(r, "faithful-name transcription typo in CSV")
      paste(r, collapse = "; ")
    }
  ) %>%
  ungroup() %>%
  arrange(code_join) %>%
  select(
    status, flag_reason, code_join, code_snapshot, code_csv,
    species_snapshot, species_csv_baron1983,
    n_snapshot, n_snapshot_num, n_csv, n_csv_num,
    volume_snapshot, volume_snapshot_num, volume_csv, volume_csv_num,
    n_match, volume_match, faithful_name_match
  )

write_csv(report, output_detail)
write_csv(filter(report, flag_reason != ""), output_mismatches)

# ---- console summary -------------------------------------------------------

message("Wrote ", output_detail)
message("Wrote ", output_mismatches)
message("Snapshot species rows:      ", nrow(snap_species))
message("CSV rows with a MOB volume: ", nrow(comparison))
message("Matched by code:            ", sum(report$status == "matched_by_code"))
message("n mismatches:               ", sum(!report$n_match, na.rm = TRUE))
message("Volume mismatches:          ", sum(!report$volume_match, na.rm = TRUE))
message("Faithful-name typos:        ", sum(report$faithful_name_match == FALSE, na.rm = TRUE))
message("Rows flagged for attention: ", sum(report$flag_reason != ""))
