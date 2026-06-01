# Baron_etal_1983_Table1_compare_to_Baron_1983_csv.R
#
# Purpose
#   Audit the formatted/analysis CSV (Baron_1983.csv) against the faithful
#   Excel snapshot of Baron et al. 1983 Table 1. The snapshot is the source of
#   truth (a faithful capture of the PDF table); the CSV is the formatted draft.
#   Rows are matched by the Baron 1983 species code, then n and MOB volume are
#   compared numerically and the original species labels are compared.
#
# Inputs
#   Baron_etal_1983_Table1_snapshot.xlsx   sheet: Table1_snapshot
#   Baron_1983.csv                         formatted comparison table
#
# Outputs
#   Baron_etal_1983_Table1_comparison_report_from_R.csv     all matched/unmatched rows
#   Baron_etal_1983_Table1_comparison_mismatches_from_R.csv  rows needing attention
#
# Fix vs the previous version
#   Baron_1983.csv contains a non-UTF-8 byte (0xCA, a Mac-Roman non-breaking
#   space) inside "Scutisorex somereni". The old reader tried UTF-8 first; R
#   hit the bad byte, emitted a *warning* (not an error) and silently truncated
#   the read there, dropping every row below it. Because it was a warning, the
#   tryCatch() latin1 fallback never fired, so 12 species (e.g. Tenrec, Suncus,
#   Tupaia, Tarsius) were wrongly reported as "missing from csv". Reading the
#   file with latin1 via readr reads every byte and fixes this.

suppressPackageStartupMessages({
  library(readxl)
  library(readr)
  library(dplyr)
  library(tidyr)
  library(stringr)
})

snapshot_file     <- "Baron_etal_1983_Table1_snapshot.xlsx"
snapshot_sheet    <- "Table1_snapshot"
comparison_file   <- "Baron_1983.csv"
output_detail     <- "Baron_etal_1983_Table1_comparison_report_from_R.csv"
output_mismatches <- "Baron_etal_1983_Table1_comparison_mismatches_from_R.csv"

# ---- helpers ---------------------------------------------------------------

# Read the faithful snapshot. Row 1 is the table caption, row 2 is the header,
# rows 3+ are data. Everything is read as text so notes/markers are preserved.
read_snapshot <- function(path, sheet) {
  raw <- read_excel(path, sheet = sheet, col_names = FALSE,
                    col_types = "text", na = c(""))
  header <- as.character(unlist(raw[2, ], use.names = FALSE))
  dat <- raw[-c(1, 2), , drop = FALSE]
  names(dat) <- header
  dat
}

# Read Baron_1983.csv robustly. latin1 reads every byte (no UTF-8 truncation);
# all columns are read as text so we control parsing explicitly.
read_baron_csv <- function(path) {
  read_csv(path,
           locale    = locale(encoding = "latin1"),
           col_types = cols(.default = col_character()),
           na        = c(""))
}

# Species code -> integer (strips leading zeros and any stray characters).
norm_code <- function(x) suppressWarnings(as.integer(str_remove_all(as.character(x), "\\D")))

# Numeric value, ignoring trailing note markers (*, +) and dash/n.a. placeholders.
parse_value <- function(x) parse_number(x, na = c("", "-", "NA", "n.a.", "__"))

# Lowercased label with footnote digits, periods and extra spaces removed,
# used only to compare the original (Baron 1983) species labels.
norm_label <- function(x) {
  x <- str_remove_all(x, "[0-9]+")
  x <- str_remove_all(x, "\\.")
  str_squish(tolower(x))
}

num_match <- function(a, b, tol = 1e-8) {
  (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & abs(a - b) <= tol)
}

# ---- snapshot: keep only the four-digit species rows -----------------------

snapshot_raw <- read_snapshot(snapshot_file, snapshot_sheet)

snap_species <- snapshot_raw %>%
  rename(code_raw = `code number of species`, species_raw = `species name`) %>%
  mutate(is_species = !is.na(code_raw) & str_detect(code_raw, "^[0-9]{4}$")) %>%
  filter(is_species) %>%
  transmute(
    code_join          = norm_code(code_raw),
    code_snapshot      = code_raw,
    species_snapshot   = species_raw,
    n_snapshot         = n,
    n_snapshot_num     = as.integer(parse_value(n)),
    volume_snapshot    = `volume in mm3`,
    volume_snapshot_num = parse_value(`volume in mm3`),
    sp_snapshot_norm   = norm_label(species_raw)
  )

# ---- CSV: keep formatted rows that actually carry a MOB volume -------------

comparison <- read_baron_csv(comparison_file) %>%
  filter(!str_detect(replace_na(Species, ""), "^AAAA_")) %>%
  filter(!is.na(Bulbus_olfactorius_1983)) %>%
  transmute(
    code_join          = norm_code(code_Baron1983),
    code_csv           = code_Baron1983,
    species_csv_baron1983 = Species_Baron1983,
    species_csv_updated   = Species,
    n_csv              = Number_of_individuals_Bulbus_olfactorius,
    n_csv_num          = as.integer(parse_value(Number_of_individuals_Bulbus_olfactorius)),
    volume_csv         = Bulbus_olfactorius_1983,
    volume_csv_num     = parse_value(Bulbus_olfactorius_1983),
    sp_csv_baron_norm  = norm_label(Species_Baron1983)
  )

# ---- compare by code -------------------------------------------------------

report <- full_join(snap_species, comparison, by = "code_join") %>%
  mutate(
    status = case_when(
      is.na(code_snapshot) ~ "csv_value_row_missing_from_snapshot",
      is.na(code_csv)      ~ "snapshot_row_missing_from_csv",
      TRUE                 ~ "matched_by_code"
    ),
    code_match           = !is.na(code_snapshot) & !is.na(code_csv),
    n_match              = num_match(n_snapshot_num, n_csv_num),
    volume_match         = num_match(volume_snapshot_num, volume_csv_num),
    # Compares the ORIGINAL Baron-1983 labels only. The CSV's updated binomial
    # (species_csv_updated) is an intentional improvement, never a mismatch.
    original_name_match  = if_else(status == "matched_by_code",
                                   sp_snapshot_norm == sp_csv_baron_norm,
                                   NA)
  ) %>%
  arrange(code_join) %>%
  select(
    status, code_join, code_snapshot, code_csv,
    species_snapshot, species_csv_baron1983, species_csv_updated,
    n_snapshot, n_snapshot_num, n_csv, n_csv_num,
    volume_snapshot, volume_snapshot_num, volume_csv, volume_csv_num,
    code_match, n_match, volume_match, original_name_match
  )

write_csv(report, output_detail)

mismatches <- report %>%
  filter(status != "matched_by_code" |
           !n_match | !volume_match |
           !coalesce(original_name_match, TRUE))
write_csv(mismatches, output_mismatches)

# ---- console summary -------------------------------------------------------

message("Wrote ", output_detail)
message("Wrote ", output_mismatches)
message("Snapshot species rows:        ", nrow(snap_species))
message("CSV rows with a MOB volume:   ", nrow(comparison))
message("Matched by code:              ", sum(report$status == "matched_by_code"))
message("Snapshot rows missing in CSV: ", sum(report$status == "snapshot_row_missing_from_csv"))
message("CSV rows missing in snapshot: ", sum(report$status == "csv_value_row_missing_from_snapshot"))
message("n mismatches:                 ", sum(!report$n_match, na.rm = TRUE))
message("Volume mismatches:            ", sum(!report$volume_match, na.rm = TRUE))
message("Original-name discrepancies:  ", sum(report$original_name_match == FALSE, na.rm = TRUE))
message("Rows flagged for attention:   ", nrow(mismatches))
