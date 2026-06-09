# Bauernfeind_etal_2013_Table1_compare_to_Bauernfeind_2013_csv.R
#
# Checking step (self-contained in comparison/). The snapshot is the per-INDIVIDUAL
# Table 1 (left insula); Bauernfeind_2013.csv holds the SPECIES means used by the
# project. So we aggregate the snapshot to species means, reproduce the CSV's
# two-Pongo-species merge ("Pongo pygmaeus and Pongo abelii" = the mean of the two
# species' means), and compare the shared measured columns to the CSV by species.
# Each CSV row is matched once (no phantom duplicates). Volumes are converted
# cm3 -> mm3 and brain mass g -> mg to match the CSV units. Body mass is NOT
# audited here (the CSV body weights come from a harmonised external source, not
# the per-individual Smith & Jungers estimates printed in Table 1).
#
# Inputs : ../Bauernfeind_etal_2013_Table1_snapshot.xlsx (sheet Table1) ; Bauernfeind_2013.csv
# Outputs: Bauernfeind_etal_2013_Table1_comparison_report_from_R.csv
#          Bauernfeind_etal_2013_Table1_comparison_mismatches_from_R.csv

suppressPackageStartupMessages({
  library(readxl); library(readr); library(dplyr); library(tidyr); library(stringr)
})
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())
  setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

snapshot_file     <- "../Bauernfeind_etal_2013_Table1_snapshot.xlsx"
snapshot_sheet    <- "Table1"
comparison_file   <- "Bauernfeind_2013.csv"
output_detail     <- "Bauernfeind_etal_2013_Table1_comparison_report_from_R.csv"
output_mismatches <- "Bauernfeind_etal_2013_Table1_comparison_mismatches_from_R.csv"
header_rows       <- 3L
measures   <- c("granular","dysgranular","agranular","FI","total_insula","brain_volume","brain_mass")
csv_col <- c(granular="Granular_insular_cortex", dysgranular="Dysgranular_insular_cortex",
             agranular="Agranular_insular_cortex", FI="fronto_insular_cortex",
             total_insula="Insula", brain_volume="Total_brain_net_volume_2013b",
             brain_mass="Brain_weight_2013b")

num <- function(x) parse_number(as.character(x), na = c("", "-", "–", "—", "NA", "n.a.", "__", "e"))
norm_label <- function(x) str_squish(tolower(str_remove_all(x, "\\.")))

# --- snapshot side: per-individual -> mm3, expand species, mean by species ---
pos <- c("species_disp","individual","collection","section_thickness_mm","age","sex",
         "body_mass_kg","social_group_size","brain_mass_g","brain_volume_cm3",
         "granular_cm3","dysgranular_cm3","agranular_cm3","FI_cm3","total_insula_cm3")
raw  <- read_excel(snapshot_file, sheet = snapshot_sheet, col_names = FALSE, col_types = "text")
sdat <- raw %>% slice(-(seq_len(header_rows))) %>% `names<-`(c(pos, rep(NA, max(0, ncol(.) - length(pos)))))
sdat <- sdat %>% filter(!is.na(individual), str_squish(individual) != "") %>%
  mutate(genus_tok = word(str_squish(species_disp), 1),
         full_genus = ifelse(str_detect(genus_tok, "\\.$"), NA_character_, genus_tok)) %>%
  fill(full_genus, .direction = "down") %>%
  mutate(species = ifelse(str_detect(genus_tok, "\\.$"),
            str_squish(paste(full_genus, word(str_squish(species_disp), 2, -1))),
            str_squish(species_disp)),
         granular = num(granular_cm3)*1000, dysgranular = num(dysgranular_cm3)*1000,
         agranular = num(agranular_cm3)*1000, FI = num(FI_cm3)*1000,
         total_insula = num(total_insula_cm3)*1000, brain_volume = num(brain_volume_cm3)*1000,
         brain_mass = num(brain_mass_g)*1000)

sp_mean <- sdat %>% group_by(species) %>%
  summarise(across(all_of(measures), ~ mean(.x, na.rm = TRUE)), n_indiv = n(), .groups = "drop") %>%
  mutate(across(all_of(measures), ~ ifelse(is.nan(.x), NA_real_, .x)),
         csv_label = ifelse(species %in% c("Pongo abelii", "Pongo pygmaeus"),
                            "Pongo pygmaeus and Pongo abelii", species))

# CSV-label value = mean of species means (identity for single-species labels; the
# Pongo label = mean of the two Pongo species' means, as the CSV computed it)
lab <- sp_mean %>% group_by(csv_label) %>%
  summarise(across(all_of(measures), ~ mean(.x, na.rm = TRUE)),
            paper_species = paste(sort(unique(species)), collapse = "; "),
            n_indiv = sum(n_indiv), .groups = "drop") %>%
  mutate(across(all_of(measures), ~ ifelse(is.nan(.x), NA_real_, .x)))

# --- csv side ---
comp <- read_csv(comparison_file, col_types = cols(.default = col_character()), na = c("")) %>%
  filter(!str_starts(replace_na(Species, ""), "AAAA_"),
         !is.na(Species_Bauernfeind2013), Species_Bauernfeind2013 != "")
csv_vals <- comp %>% transmute(csv_label = str_squish(Species_Bauernfeind2013),
  granular_csv = num(.data[[csv_col[["granular"]]]]), dysgranular_csv = num(.data[[csv_col[["dysgranular"]]]]),
  agranular_csv = num(.data[[csv_col[["agranular"]]]]), FI_csv = num(.data[[csv_col[["FI"]]]]),
  total_insula_csv = num(.data[[csv_col[["total_insula"]]]]), brain_volume_csv = num(.data[[csv_col[["brain_volume"]]]]),
  brain_mass_csv = num(.data[[csv_col[["brain_mass"]]]]))

num_match <- function(a, b, tol = 0.05) (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & abs(a - b) <= tol)
report <- full_join(lab %>% rename_with(~ paste0(.x, "_snap"), all_of(measures)),
                    csv_vals, by = "csv_label") %>%
  mutate(status = case_when(is.na(paper_species) ~ "csv_only_not_in_snapshot",
                            if_all(ends_with("_csv"), is.na) & !is.na(paper_species) ~ "snapshot_only_not_in_csv",
                            TRUE ~ "matched_by_species"))
for (m in measures)
  report[[paste0(m, "_match")]] <- num_match(report[[paste0(m, "_snap")]], report[[paste0(m, "_csv")]])
report$n_measure_mismatch <- rowSums(!as.matrix(report[paste0(measures, "_match")]), na.rm = TRUE)
report <- report %>% arrange(csv_label) %>%
  relocate(status, csv_label, paper_species, n_indiv, n_measure_mismatch)

write_csv(report, output_detail)
write_csv(filter(report, status != "matched_by_species" | n_measure_mismatch > 0), output_mismatches)
message("matched species: ", sum(report$status == "matched_by_species"),
        " | value mismatches: ", sum(report$n_measure_mismatch > 0 & report$status == "matched_by_species", na.rm = TRUE),
        " | snapshot-only: ", sum(report$status == "snapshot_only_not_in_csv"),
        " | csv-only: ", sum(report$status == "csv_only_not_in_snapshot"))
