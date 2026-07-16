# Seymour_etal_2015_TableS1_compare_to_Seymour_brainbody_csv.R
#
# Checking step (self-contained in comparison/). Audit the journal-faithful
# snapshot of Seymour et al. (2015) Table S1 against the curated
# "Seymour data added to compilation/Seymour_2015_TableS1_brainbody.csv",
# matched by species name, comparing the shared measured columns: body mass (g)
# and brain/endocranial volume (ml), plus the body-mass reference number. The
# curated file's derived "Brain mass (g)" (= Vbr x 1.036) is additionally checked
# as a derivation audit. Snapshot morphometrics (radii, shear, QICA) are not in
# the curated file and are not audited here. Run from comparison/.
#
# Inputs : ../Seymour_etal_2015_TableS1_snapshot.xlsx (sheet TableS1)
#          Seymour data added to compilation/Seymour_2015_TableS1_brainbody.csv
# Outputs: Seymour_etal_2015_TableS1_comparison_report_from_R.csv
#          Seymour_etal_2015_TableS1_comparison_mismatches_from_R.csv

suppressPackageStartupMessages({
  library(readxl); library(readr); library(dplyr); library(tidyr); library(stringr)
})
setwd("/Users/crossmodal/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/Seymour_etal_2015/comparison")
snapshot_file  <- "../Seymour_etal_2015_TableS1_snapshot.xlsx"
snapshot_sheet <- "TableS1"
comparison_file <- "Seymour data added to compilation/Seymour_2015_TableS1_brainbody.csv"
output_detail     <- "Seymour_etal_2015_TableS1_comparison_report_from_R.csv"
output_mismatches <- "Seymour_etal_2015_TableS1_comparison_mismatches_from_R.csv"

parse_value <- function(x) parse_number(as.character(x), na = c("", "-", "NA", "n.a."))
clean6      <- function(x) signif(x, 6)
norm_label  <- function(x) str_squish(tolower(x))

# ---- snapshot: reduce to species rows (Family present, integer Number) ----
raw <- read_excel(snapshot_file, sheet = snapshot_sheet, col_names = FALSE, col_types = "text")
names(raw) <- paste0("V", seq_len(ncol(raw)))
snap <- raw %>%
  filter(!is.na(V3), str_squish(V3) != "Family",
         str_detect(replace_na(V4, ""), "^[0-9]+$")) %>%
  transmute(species_key      = norm_label(V1),
            species_snapshot = str_squish(V1),
            body_mass_g_snap = clean6(parse_value(V5)),
            brain_vol_ml_snap = clean6(parse_value(V7)),
            ref_snap         = parse_value(V6))

# ---- curated CSV ----
comp_raw <- read_csv(comparison_file, col_types = cols(.default = col_character())) %>%
  mutate(.cid = row_number())
comp <- comp_raw %>% transmute(.cid,
  species_csv      = str_squish(`Seymour2015 Species`),
  body_mass_g_csv  = parse_value(`Body mass (g)`),
  brain_vol_ml_csv = parse_value(`Endocranial volume (ml)`),
  brain_mass_g_csv = parse_value(`Brain mass (g)`),
  ref_csv          = parse_value(Reference))
snap <- snap %>% mutate(.cid = comp_raw$.cid[match(species_key, norm_label(comp_raw$`Seymour2015 Species`))])

num_match <- function(a, b, tol = 1e-4) (is.na(a) & is.na(b)) |
  (!is.na(a) & !is.na(b) & abs(a - b) <= pmax(tol, abs(b) * tol))

report <- full_join(snap, comp, by = ".cid") %>%
  mutate(brain_mass_g_snap = clean6(brain_vol_ml_snap * 1.036),
         status = case_when(is.na(species_snapshot) ~ "csv_only_not_in_snapshot",
                            is.na(species_csv)      ~ "snapshot_only_not_in_csv",
                            TRUE                    ~ "matched_by_species"),
         body_mass_match  = num_match(body_mass_g_snap,  body_mass_g_csv),
         brain_vol_match  = num_match(brain_vol_ml_snap, brain_vol_ml_csv),
         brain_mass_match = num_match(brain_mass_g_snap, brain_mass_g_csv),
         ref_match        = num_match(ref_snap, ref_csv, tol = 0)) %>%
  mutate(n_mismatch = (!body_mass_match) + (!brain_vol_match) + (!brain_mass_match) + (!ref_match)) %>%
  arrange(coalesce(species_snapshot, species_csv)) %>%
  relocate(status, species_snapshot, species_csv, n_mismatch)

write_csv(report, output_detail)
write_csv(filter(report, status != "matched_by_species" | n_mismatch > 0), output_mismatches)
message("matched: ", sum(report$status == "matched_by_species"),
        " | rows with a value mismatch: ", sum(report$n_mismatch > 0, na.rm = TRUE),
        " | snapshot-only: ", sum(report$status == "snapshot_only_not_in_csv"),
        " | csv-only: ", sum(report$status == "csv_only_not_in_snapshot"))
