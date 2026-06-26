# Smaers_etal_2017_TableS1part2_compare_to_Brodmann_csv.R
#
# Checking step (self-contained in comparison/). Audit the journal-faithful SURFACE-AREA
# snapshot (Smaers 2017 Table S1, part 2 = Brodmann data) against the independent
# formatted file Brodmann_surface_1909.csv (derived from the separate publisher file
# "cortical surfaces Brodmann 1909 in Smears et al 2017.xlsx"). Because the snapshot and
# the comparison csv are two independent digitisations of the same Table S1 block, a
# clean match confirms the transcription. Matched by species (genus+species). Run from comparison/.
#
# Inputs : ../Smaers_etal_2017_TableS1part2_snapshot.xlsx (sheet surface_area) ; Brodmann_surface_1909.csv
# Outputs: Smaers_etal_2017_TableS1part2_comparison_report_from_R.csv
#          Smaers_etal_2017_TableS1part2_comparison_mismatches_from_R.csv

suppressPackageStartupMessages({
  library(readxl); library(readr); library(dplyr); library(tidyr); library(stringr)
})
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())
  setwd("/Users/crossmodal/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/_setwd_backup/_setwd_backup/Smaers_etal_2017/comparison")

snapshot_file     <- "../Smaers_etal_2017_TableS1part2_snapshot.xlsx"
snapshot_sheet    <- "surface_area"
comparison_file   <- "Brodmann_surface_1909.csv"
output_detail     <- "Smaers_etal_2017_TableS1part2_comparison_report_from_R.csv"
output_mismatches <- "Smaers_etal_2017_TableS1part2_comparison_mismatches_from_R.csv"
header_rows       <- 3L

csv_col <- c(
  primary_visual_surface    = "Primary visual",
  prefrontal_surface        = "Prefrontal",
  other_association_surface = "Other cortical association areas",
  frontal_motor_surface     = "Frontal motor"
)
structures <- names(csv_col)

parse_value <- function(x) parse_number(as.character(x), na = c("", "-", "NA", "n.a.", "__"))
sp_key <- function(x) {
  x <- tolower(str_squish(str_replace_all(x, "_", " ")))
  vapply(str_split(x, " "), function(p) paste(head(p, 2), collapse = " "), character(1))
}

pos  <- c("species_disp","primary_visual_surface","prefrontal_surface",
          "other_association_surface","frontal_motor_surface")
raw  <- read_excel(snapshot_file, sheet = snapshot_sheet, col_names = FALSE, col_types = "text")
sdat <- raw %>% slice(-(seq_len(header_rows)))
names(sdat)[seq_along(pos)] <- pos

snap <- sdat %>%
  filter(!is.na(species_disp), species_disp != "") %>%
  transmute(species_key = sp_key(species_disp), species_snapshot = str_squish(species_disp),
            primary_visual_surface_snap    = parse_value(primary_visual_surface),
            prefrontal_surface_snap        = parse_value(prefrontal_surface),
            other_association_surface_snap = parse_value(other_association_surface),
            frontal_motor_surface_snap     = parse_value(frontal_motor_surface))

comp <- read_csv(comparison_file, col_types = cols(.default = col_character()), na = c("")) %>%
  filter(!is.na(Species), Species != "") %>%
  transmute(species_key = sp_key(Species), species_csv = str_squish(Species),
            primary_visual_surface_csv    = parse_value(.data[[csv_col[["primary_visual_surface"]]]]),
            prefrontal_surface_csv        = parse_value(.data[[csv_col[["prefrontal_surface"]]]]),
            other_association_surface_csv = parse_value(.data[[csv_col[["other_association_surface"]]]]),
            frontal_motor_surface_csv     = parse_value(.data[[csv_col[["frontal_motor_surface"]]]]))

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
