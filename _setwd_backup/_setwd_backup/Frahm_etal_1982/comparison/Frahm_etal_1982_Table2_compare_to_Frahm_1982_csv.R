# Frahm_etal_1982_Table2_compare_to_Frahm_1982_csv.R
#
# Checking step (self-contained in comparison/). Audit the journal-faithful
# snapshot of Frahm & Stephan (1982) Table 2 (neocortex volumes) against
# Frahm_1982.csv, matched by species name, comparing the five volumes (total
# neocortex, white matter, grey matter, lamina 1, laminae 2-6) and n. The
# snapshot's two computed % columns are not in the CSV and are not audited here.
# Run from comparison/.
#
# Snapshot layout: row1 caption, row2 headers, row3 column numbers, then species
# rows (col A = species, n>1 in parentheses) + 7 measures (cols B-H), blank rows
# separating groups.
#
# Inputs : ../Frahm_etal_1982_Table2_snapshot.xlsx (sheet Table2) ; Frahm_1982.csv
# Outputs: Frahm_etal_1982_Table2_comparison_report_from_R.csv
#          Frahm_etal_1982_Table2_comparison_mismatches_from_R.csv

suppressPackageStartupMessages({
  library(readxl); library(readr); library(dplyr); library(tidyr); library(stringr)
})
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())
  setwd("/Users/crossmodal/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/_setwd_backup/_setwd_backup/Frahm_etal_1982/comparison")

snapshot_file     <- "../Frahm_etal_1982_Table2_snapshot.xlsx"
snapshot_sheet    <- "Table2"
comparison_file   <- "Frahm_1982.csv"
output_detail     <- "Frahm_etal_1982_Table2_comparison_report_from_R.csv"
output_mismatches <- "Frahm_etal_1982_Table2_comparison_mismatches_from_R.csv"
header_rows       <- 3L
structures <- c("total_neocortex","white_matter","grey_matter","lamina_1","laminae_2_6","n")
csv_col <- c(total_neocortex="Neocortex_1982", white_matter="Neocortex_white_matter",
             grey_matter="Neocortex_grey_matter", lamina_1="Neocortex_lam_1",
             laminae_2_6="Neocortex_lam_2_6", n="Number_of_individuals_neocortex")

parse_value <- function(x) parse_number(as.character(x), na = c("", "-", "NA", "n.a.", "__"))
norm_label  <- function(x) str_squish(tolower(str_remove_all(str_remove(x, "\\s*\\(\\d+\\)\\s*$"), "\\.")))

pos <- c("species_disp","total_neocortex","white_matter","white_pct_neocortex",
         "grey_matter","lamina_1","lamina_1_pct_grey","laminae_2_6")
raw <- read_excel(snapshot_file, sheet = snapshot_sheet, col_names = FALSE, col_types = "text")
sdat <- raw %>% slice(-(seq_len(header_rows)))
names(sdat)[seq_along(pos)] <- pos

snap <- sdat %>%
  filter(!is.na(species_disp), str_squish(species_disp) != "", !is.na(parse_value(total_neocortex))) %>%
  transmute(species_key = norm_label(species_disp),
            species_snapshot = str_squish(str_remove(species_disp, "\\s*\\(\\d+\\)\\s*$")),
            total_neocortex_snap = parse_value(total_neocortex),
            white_matter_snap    = parse_value(white_matter),
            grey_matter_snap     = parse_value(grey_matter),
            lamina_1_snap        = parse_value(lamina_1),
            laminae_2_6_snap     = parse_value(laminae_2_6),
            n_snap               = ifelse(str_detect(species_disp, "\\((\\d+)\\)\\s*$"),
                                          parse_value(str_match(species_disp, "\\((\\d+)\\)\\s*$")[, 2]), 1))

# ONE row per physical CSV entry (the file repeats some info). The CSV's
# Species_Frahm1982 has OCR artifacts, so match each snapshot species to a CSV
# row by EITHER the 1982 name OR the canonical Species -- but resolve to a single
# row id so the alternate key never produces a phantom "csv_only" duplicate.
comp_raw <- read_csv(comparison_file, col_types = cols(.default = col_character()), na = c("")) %>%
  filter(!str_starts(replace_na(Species, ""), "AAAA_"),
         !is.na(.data[[csv_col[["total_neocortex"]]]]), .data[[csv_col[["total_neocortex"]]]] != "") %>%
  mutate(.cid = row_number())
snap <- snap %>% mutate(.cid = dplyr::coalesce(
  comp_raw$.cid[match(species_key, norm_label(comp_raw$Species_Frahm1982))],
  comp_raw$.cid[match(species_key, norm_label(comp_raw$Species))]))
comp <- comp_raw %>% transmute(.cid,
  species_csv = str_squish(dplyr::coalesce(Species_Frahm1982, Species)),
  total_neocortex_csv = parse_value(.data[[csv_col[["total_neocortex"]]]]),
  white_matter_csv    = parse_value(.data[[csv_col[["white_matter"]]]]),
  grey_matter_csv     = parse_value(.data[[csv_col[["grey_matter"]]]]),
  lamina_1_csv        = parse_value(.data[[csv_col[["lamina_1"]]]]),
  laminae_2_6_csv     = parse_value(.data[[csv_col[["laminae_2_6"]]]]),
  n_csv               = parse_value(.data[[csv_col[["n"]]]]))

num_match <- function(a, b, tol = 1e-6) (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & abs(a - b) <= tol)
report <- full_join(snap, comp, by = ".cid") %>%
  mutate(status = case_when(is.na(species_snapshot) ~ "csv_only_not_in_snapshot",
                            is.na(species_csv)      ~ "snapshot_only_not_in_csv",
                            TRUE                    ~ "matched_by_species"))
for (s in structures)
  report[[paste0(s, "_match")]] <- num_match(report[[paste0(s, "_snap")]], report[[paste0(s, "_csv")]])
report$n_measure_mismatch <- rowSums(!as.matrix(report[paste0(structures, "_match")]))
report <- report %>% arrange(dplyr::coalesce(species_snapshot, species_csv)) %>%
  relocate(status, species_snapshot, species_csv, n_measure_mismatch)

write_csv(report, output_detail)
write_csv(filter(report, status != "matched_by_species" | n_measure_mismatch > 0), output_mismatches)
message("matched: ", sum(report$status == "matched_by_species"),
        " | value mismatches: ", sum(report$n_measure_mismatch > 0, na.rm = TRUE),
        " | snapshot-only: ", sum(report$status == "snapshot_only_not_in_csv"),
        " | csv-only: ", sum(report$status == "csv_only_not_in_snapshot"))
