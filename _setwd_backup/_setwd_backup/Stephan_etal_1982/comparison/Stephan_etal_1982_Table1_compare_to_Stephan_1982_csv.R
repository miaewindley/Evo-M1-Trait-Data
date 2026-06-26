# Stephan_etal_1982_Table1_compare_to_Stephan_1982_csv.R
#
# Checking step (self-contained in comparison/). Audit the journal-faithful
# snapshot of Stephan, Baron & Frahm (1982) Table 1 against Stephan_1982.csv,
# matched by the 1982 species name (superscripts stripped), comparing the columns
# the two share: total AOB volume, the three layer volumes, and n. The snapshot's
# derived columns (size_index, pct_AOB, per-mille) are not in the CSV; they are
# validated separately by recomputation (see the README). Run from comparison/.
#
# Inputs : ../Stephan_etal_1982_Table1_snapshot.xlsx (sheet Table1) ; Stephan_1982.csv
# Outputs: Stephan_etal_1982_Table1_comparison_report_from_R.csv
#          Stephan_etal_1982_Table1_comparison_mismatches_from_R.csv

suppressPackageStartupMessages({
  library(readxl); library(readr); library(dplyr); library(tidyr); library(stringr)
})
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())
  setwd("/Users/crossmodal/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/_setwd_backup/_setwd_backup/Stephan_etal_1982/comparison")

snapshot_file     <- "../Stephan_etal_1982_Table1_snapshot.xlsx"
snapshot_sheet    <- "Table1"
comparison_file   <- "Stephan_1982.csv"
output_detail     <- "Stephan_etal_1982_Table1_comparison_report_from_R.csv"
output_mismatches <- "Stephan_etal_1982_Table1_comparison_mismatches_from_R.csv"
header_rows       <- 5L
structures        <- c("AOB_volume", "AOB_layer_1_2", "AOB_layer_3_5", "AOB_layer_6", "n")

# CSV column for each shared measure
csv_col <- c(
  AOB_volume    = "Bulbus_olfactorius_accessorius_1982",
  AOB_layer_1_2 = "Bulbus_olfactorius_accessorius_layers_1_2",
  AOB_layer_3_5 = "Bulbus_olfactorius_accessorius_layers_3_5",
  AOB_layer_6   = "Bulbus_olfactorius_accessorius_layers_6",
  n             = "Number_of_individuals_Bulbus_olfactorius_accessorius"
)

parse_value <- function(x) parse_number(as.character(x), na = c("", "-", "NA", "n.a.", "__"))
norm_label  <- function(x) str_squish(tolower(str_remove_all(str_remove_all(x, "[¹²³⁴⁵⁶⁷⁸⁹⁰]"), "\\.")))

# --- snapshot side: read by position (multi-row journal header), keep species rows ---
pos <- c("species_disp","n_raw","volume","SEM_pct","size_index",
  "permille_net_brain","permille_MOB","AOB_layer_1_2","AOB_layer_3_5","AOB_layer_6",
  "pct_AOB_1_2","pct_AOB_3_5","pct_AOB_6","size_index_1_2","size_index_3_5","size_index_6")
raw <- read_excel(snapshot_file, sheet = snapshot_sheet, col_names = FALSE, col_types = "text")
sdat <- raw %>% slice(-(seq_len(header_rows)))
names(sdat)[seq_along(pos)] <- pos

snap <- sdat %>%
  filter(!is.na(species_disp), species_disp != "", !is.na(parse_value(volume))) %>%
  transmute(species_key      = norm_label(species_disp),
            species_snapshot = str_squish(str_remove_all(species_disp, "[¹²³⁴⁵⁶⁷⁸⁹⁰]")),
            AOB_volume_snap    = parse_value(volume),
            AOB_layer_1_2_snap = parse_value(AOB_layer_1_2),
            AOB_layer_3_5_snap = parse_value(AOB_layer_3_5),
            AOB_layer_6_snap   = parse_value(AOB_layer_6),
            n_snap             = parse_value(n_raw))

comp <- read_csv(comparison_file, col_types = cols(.default = col_character()), na = c("")) %>%
  filter(!str_starts(replace_na(Species, ""), "AAAA_"),
         !is.na(Species_Stephan1982), Species_Stephan1982 != "",
         !is.na(.data[[csv_col[["AOB_volume"]]]])) %>%
  transmute(species_key       = norm_label(Species_Stephan1982),
            species_csv       = str_squish(Species_Stephan1982),
            AOB_volume_csv    = parse_value(.data[[csv_col[["AOB_volume"]]]]),
            AOB_layer_1_2_csv = parse_value(.data[[csv_col[["AOB_layer_1_2"]]]]),
            AOB_layer_3_5_csv = parse_value(.data[[csv_col[["AOB_layer_3_5"]]]]),
            AOB_layer_6_csv   = parse_value(.data[[csv_col[["AOB_layer_6"]]]]),
            n_csv             = parse_value(.data[[csv_col[["n"]]]]))

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
