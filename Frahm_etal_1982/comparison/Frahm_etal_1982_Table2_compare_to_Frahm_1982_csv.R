# Frahm_etal_1982_Table2_compare_to_Frahm_1982_csv.R
#
# Checking step (self-contained in comparison/). Audit the journal-faithful
# snapshot of Frahm & Stephan (1982) Table 2 (neocortex volumes) against
# Frahm_1982.csv, matched by the 1982 species name (superscripts stripped),
# comparing the five volumes (total neocortex, white matter, grey matter,
# lamina 1, laminae 2-6) and n. The snapshot's two computed % columns are not in
# the CSV and are not part of this audit. Run from comparison/.
#
# Inputs : ../Frahm_etal_1982_Table2_snapshot.xlsx (sheet Table2) ; Frahm_1982.csv
# Outputs: Frahm_etal_1982_Table2_comparison_report_from_R.csv
#          Frahm_etal_1982_Table2_comparison_mismatches_from_R.csv

suppressPackageStartupMessages({
  library(readxl); library(readr); library(dplyr); library(tidyr); library(stringr)
})
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())
  setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

snapshot_file     <- "../Frahm_etal_1982_Table2_snapshot.xlsx"
snapshot_sheet    <- "Table2"
comparison_file   <- "Frahm_1982.csv"
output_detail     <- "Frahm_etal_1982_Table2_comparison_report_from_R.csv"
output_mismatches <- "Frahm_etal_1982_Table2_comparison_mismatches_from_R.csv"
header_rows       <- 4L
structures <- c("total_neocortex","white_matter","grey_matter","lamina_1","laminae_2_6","n")
csv_col <- c(total_neocortex="Neocortex_1982", white_matter="Neocortex_white_matter",
             grey_matter="Neocortex_grey_matter", lamina_1="Neocortex_lam_1",
             laminae_2_6="Neocortex_lam_2_6", n="Number_of_individuals_neocortex")

parse_value <- function(x) parse_number(as.character(x), na = c("", "-", "NA", "n.a.", "__"))
norm_label  <- function(x) str_squish(tolower(str_remove_all(str_remove_all(x, "[¹²³⁴⁵⁶⁷⁸⁹⁰]"), "\\.")))

pos <- c("group_raw","family_raw","species_disp","n_raw","total_neocortex","white_matter",
  "white_pct_neocortex","grey_matter","lamina_1","lamina_1_pct_grey","laminae_2_6")
raw <- read_excel(snapshot_file, sheet = snapshot_sheet, col_names = FALSE, col_types = "text")
sdat <- raw %>% slice(-(seq_len(header_rows)))
names(sdat)[seq_along(pos)] <- pos

snap <- sdat %>%
  filter(!is.na(species_disp), species_disp != "", !is.na(parse_value(total_neocortex))) %>%
  transmute(species_key = norm_label(species_disp),
            species_snapshot = str_squish(str_remove_all(species_disp, "[¹²³⁴⁵⁶⁷⁸⁹⁰]")),
            total_neocortex_snap = parse_value(total_neocortex),
            white_matter_snap    = parse_value(white_matter),
            grey_matter_snap     = parse_value(grey_matter),
            lamina_1_snap        = parse_value(lamina_1),
            laminae_2_6_snap     = parse_value(laminae_2_6),
            n_snap               = parse_value(n_raw))

# The snapshot uses clean journal names; the CSV's Species_Frahm1982 has a few OCR
# artifacts (e.g. "Microceblls murinus", truncated "Daubentonia madagascar.", a
# blank name for Pongo). Match on EITHER the 1982 name OR the canonical Species,
# so cleaned snapshot names still resolve.
comp_raw <- read_csv(comparison_file, col_types = cols(.default = col_character()), na = c("")) %>%
  filter(!str_starts(replace_na(Species, ""), "AAAA_"),
         !is.na(.data[[csv_col[["total_neocortex"]]]]), .data[[csv_col[["total_neocortex"]]]] != "")
mk <- function(keycol) comp_raw %>%
  filter(!is.na(.data[[keycol]]), .data[[keycol]] != "") %>%
  transmute(species_key = norm_label(.data[[keycol]]),
            species_csv = str_squish(dplyr::coalesce(Species_Frahm1982, Species)),
            total_neocortex_csv = parse_value(.data[[csv_col[["total_neocortex"]]]]),
            white_matter_csv    = parse_value(.data[[csv_col[["white_matter"]]]]),
            grey_matter_csv     = parse_value(.data[[csv_col[["grey_matter"]]]]),
            lamina_1_csv        = parse_value(.data[[csv_col[["lamina_1"]]]]),
            laminae_2_6_csv     = parse_value(.data[[csv_col[["laminae_2_6"]]]]),
            n_csv               = parse_value(.data[[csv_col[["n"]]]]))
comp <- bind_rows(mk("Species_Frahm1982"), mk("Species")) %>% distinct(species_key, .keep_all = TRUE)

num_match <- function(a, b, tol = 1e-6) (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & abs(a - b) <= tol)
report <- full_join(snap, comp, by = "species_key") %>%
  mutate(status = case_when(is.na(species_snapshot) ~ "csv_only_not_in_snapshot",
                            is.na(species_csv)      ~ "snapshot_only_not_in_csv",
                            TRUE                    ~ "matched_by_species"))
for (s in structures)
  report[[paste0(s, "_match")]] <- num_match(report[[paste0(s, "_snap")]], report[[paste0(s, "_csv")]])
report$n_measure_mismatch <- rowSums(!as.matrix(report[paste0(structures, "_match")]))
report <- report %>% arrange(species_key) %>%
  relocate(status, species_key, species_snapshot, species_csv, n_measure_mismatch)

write_csv(report, output_detail)
write_csv(filter(report, status != "matched_by_species" | n_measure_mismatch > 0), output_mismatches)
message("matched: ", sum(report$status == "matched_by_species"),
        " | value mismatches: ", sum(report$n_measure_mismatch > 0, na.rm = TRUE),
        " | snapshot-only: ", sum(report$status == "snapshot_only_not_in_csv"),
        " | csv-only: ", sum(report$status == "csv_only_not_in_snapshot"))
