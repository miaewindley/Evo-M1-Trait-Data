# Baron_etal_1988_Table1_compare_to_Baron_1988_csv.R
#
# Checking step (self-contained in comparison/). Audit the snapshot of Baron et
# al. 1988 Table 1 against Baron_1988.csv, matched by species, comparing the five
# vestibular-complex volumes (VC, VI, VL, VM, VS). Run from the comparison/ folder.
#
# Inputs : ../Baron_etal_1988_Table1_snapshot.xlsx ; Baron_1988.csv (same folder)
# Outputs: Baron_etal_1988_Table1_comparison_report_from_R.csv
#          Baron_etal_1988_Table1_comparison_mismatches_from_R.csv

suppressPackageStartupMessages({
  library(readxl); library(readr); library(dplyr); library(tidyr); library(stringr)
})
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())
  setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

snapshot_file     <- "../Baron_etal_1988_Table1_snapshot.xlsx"
snapshot_sheet    <- "Table1_snapshot"
comparison_file   <- "Baron_1988.csv"
output_detail     <- "Baron_etal_1988_Table1_comparison_report_from_R.csv"
output_mismatches <- "Baron_etal_1988_Table1_comparison_mismatches_from_R.csv"
structures <- c("VC", "VI", "VL", "VM", "VS")

full_to_code <- c(
  Complexus_vestibularis_1988_both_sides          = "VC",
  Nucleus_vestibularis_descendens_1988_both_sides = "VI",
  Nucleus_vestibularis_lateralis_1988_both_sides  = "VL",
  Nucleus_vestibularis_medialis_1988_both_sides   = "VM",
  Nucleus_vestibularis_superior_1988_both_sides   = "VS"
)

read_snapshot <- function(path, sheet) {
  raw <- read_excel(path, sheet = sheet, col_names = FALSE, col_types = "text", na = c(""))
  header <- as.character(unlist(raw[2, ], use.names = FALSE))
  blank <- is.na(header) | header == ""; header[blank] <- paste0("blank_", which(blank))
  dat <- raw[-c(1, 2), , drop = FALSE]; names(dat) <- header; dat
}
parse_value <- function(x) parse_number(x, na = c("", "-", "NA", "n.a.", "__"))
norm_label  <- function(x) str_squish(tolower(str_remove_all(x, "\\.")))
num_match   <- function(a, b, tol = 1e-6) (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & abs(a - b) <= tol)

snap <- read_snapshot(snapshot_file, snapshot_sheet) %>%
  rename(species_snapshot = `species name`) %>%
  filter(!is.na(species_snapshot)) %>%
  transmute(species_key = norm_label(species_snapshot), species_snapshot,
            across(all_of(structures), parse_value, .names = "{.col}_snap"))

comp <- read_csv(comparison_file, col_types = cols(.default = col_character()), na = c("")) %>%
  filter(!str_detect(replace_na(Species, ""), "^AAAA_")) %>%
  rename(any_of(setNames(names(full_to_code), full_to_code))) %>%
  filter(!is.na(VC)) %>%
  transmute(species_key = norm_label(Species_Baron1988), species_csv = Species_Baron1988,
            across(all_of(structures), parse_value, .names = "{.col}_csv"))

report <- full_join(snap, comp, by = "species_key") %>%
  mutate(status = case_when(is.na(species_snapshot) ~ "csv_only_not_in_snapshot",
                            is.na(species_csv)      ~ "snapshot_only_not_in_csv",
                            TRUE                    ~ "matched_by_species"))
for (s in structures)
  report[[paste0(s, "_match")]] <- num_match(report[[paste0(s, "_snap")]], report[[paste0(s, "_csv")]])
report$n_structure_mismatch <- rowSums(!as.matrix(report[paste0(structures, "_match")]))
report <- report %>% arrange(species_key) %>%
  relocate(status, species_key, species_snapshot, species_csv, n_structure_mismatch)

write_csv(report, output_detail)
write_csv(filter(report, status != "matched_by_species" | n_structure_mismatch > 0), output_mismatches)
message("matched: ", sum(report$status == "matched_by_species"),
        " | value mismatches: ", sum(report$n_structure_mismatch > 0, na.rm = TRUE),
        " | snapshot-only: ", sum(report$status == "snapshot_only_not_in_csv"),
        " | csv-only: ", sum(report$status == "csv_only_not_in_snapshot"))
