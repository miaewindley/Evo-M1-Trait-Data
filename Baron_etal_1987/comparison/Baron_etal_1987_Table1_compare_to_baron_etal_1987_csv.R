# Baron_etal_1987_Table1_compare_to_baron_etal_1987_csv.R
#
# Purpose
#   Checking step (self-contained in this comparison/ folder). Audit the faithful
#   snapshot of Baron et al. 1987 Table 1 against the formatted table Baron_1987.csv.
#   Rows are matched by the Baron 1987 species name, then all seven paleocortical
#   structure volumes (BOL, RB, PRPI, TOL, TRL, COA, SIN) are compared numerically.
#
# Inputs (run this script from the comparison/ folder)
#   ../Baron_etal_1987_Table1_snapshot.xlsx   sheet: Table1_snapshot
#   Baron_1987.csv                            formatted table (same folder)
#
# Outputs (written here in comparison/)
#   Baron_etal_1987_Table1_comparison_report_from_R.csv       every species, all 7 structures
#   Baron_etal_1987_Table1_comparison_mismatches_from_R.csv   rows needing attention

suppressPackageStartupMessages({
  library(readxl)
  library(readr)
  library(dplyr)
  library(tidyr)
  library(stringr)
})

# Run from this script's own folder (RStudio), so the relative paths resolve.
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
## Set working directory to this script folder
setwd("/Users/crossmodal/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/Baron_etal_1987/comparison")
}

snapshot_file     <- "../Baron_etal_1987_Table1_snapshot.xlsx"
snapshot_sheet    <- "Table1_snapshot"
comparison_file   <- "Baron_1987.csv"
output_detail     <- "Baron_etal_1987_Table1_comparison_report_from_R.csv"
output_mismatches <- "Baron_etal_1987_Table1_comparison_mismatches_from_R.csv"

structures <- c("BOL", "RB", "PRPI", "TOL", "TRL", "COA", "SIN")

# Baron_1987.csv uses full structure names; map them to the snapshot's codes.
full_to_code <- c(
  Bulbus_olfactorius_1987       = "BOL",
  Retrobulbar_cortex            = "RB",
  Prepiriform_cortex            = "PRPI",
  Tuberculum_olfactorium        = "TOL",
  Tractus_olfactorius_lateralis = "TRL",
  Commissura_anterior           = "COA",
  Substantia_innominata         = "SIN"
)

# ---- helpers ---------------------------------------------------------------

read_snapshot <- function(path, sheet) {
  raw <- read_excel(path, sheet = sheet, col_names = FALSE, col_types = "text", na = c(""))
  header <- as.character(unlist(raw[2, ], use.names = FALSE))
  blank <- is.na(header) | header == ""
  header[blank] <- paste0("blank_", which(blank))
  dat <- raw[-c(1, 2), , drop = FALSE]
  names(dat) <- header
  dat
}
parse_value <- function(x) parse_number(x, na = c("", "-", "NA", "n.a.", "__"))
norm_label  <- function(x) str_squish(tolower(str_remove_all(x, "\\.")))
num_match   <- function(a, b, tol = 1e-6) {
  (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & abs(a - b) <= tol)
}

# ---- read both sources, keep species rows, make values numeric -------------

snap <- read_snapshot(snapshot_file, snapshot_sheet) %>%
  rename(species_snapshot = `species name`) %>%
  filter(!is.na(species_snapshot)) %>%                 # drops group + footnote rows
  transmute(species_key = norm_label(species_snapshot), species_snapshot,
            across(all_of(structures), parse_value, .names = "{.col}_snap"))

comp <- read_csv(comparison_file, col_types = cols(.default = col_character()), na = c("")) %>%
  filter(!str_detect(replace_na(Species, ""), "^AAAA_")) %>%
  rename(any_of(setNames(names(full_to_code), full_to_code))) %>%   # full names -> codes
  filter(!is.na(BOL)) %>%
  transmute(species_key = norm_label(Species),
            species_csv = Species,
            species_csv_updated = Species,
            across(all_of(structures), parse_value, .names = "{.col}_csv"))

# ---- match by species and compare every structure --------------------------

report <- full_join(snap, comp, by = "species_key") %>%
  mutate(status = case_when(
    is.na(species_snapshot) ~ "csv_only_not_in_snapshot",
    is.na(species_csv)      ~ "snapshot_only_not_in_csv",
    TRUE                    ~ "matched_by_species"
  ))

for (s in structures) {
  report[[paste0(s, "_match")]] <- num_match(report[[paste0(s, "_snap")]],
                                             report[[paste0(s, "_csv")]])
}
report$n_structure_mismatch <- rowSums(!as.matrix(report[paste0(structures, "_match")]))

report <- report %>%
  arrange(species_key) %>%
  relocate(status, species_key, species_snapshot, species_csv, species_csv_updated,
           n_structure_mismatch)

write_csv(report, output_detail)
write_csv(filter(report, status != "matched_by_species" | n_structure_mismatch > 0),
          output_mismatches)

# ---- console summary -------------------------------------------------------

message("Wrote ", output_detail)
message("Wrote ", output_mismatches)
message("Snapshot species:            ", sum(!is.na(report$species_snapshot)))
message("CSV species (with values):   ", sum(!is.na(report$species_csv)))
message("Matched by species:          ", sum(report$status == "matched_by_species"))
message("Snapshot-only species:       ", sum(report$status == "snapshot_only_not_in_csv"))
message("CSV-only species:            ", sum(report$status == "csv_only_not_in_snapshot"))
message("Species with value mismatch: ", sum(report$n_structure_mismatch > 0, na.rm = TRUE))
