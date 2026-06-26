# Smaers_etal_2017_TableS1part1_compare_to_Smaers_csv.R
#
# Checking step (self-contained in comparison/). Audit the journal-faithful VOLUME
# snapshot (Smaers 2017 Table S1, part 1) against the pre-existing formatted
# comparison table Smaers.csv, matched by species (normalised to genus+species so the
# snapshot's trinomials Gorilla gorilla gorilla / Pan troglodytes troglodytes match the
# csv's binomials). The csv carries 7 of the 8 volume columns (it lacks primary-visual
# GRAY), so primary_visual_gray shows up as snapshot-only. Run from comparison/.
#
# Inputs : ../Smaers_etal_2017_TableS1part1_snapshot.xlsx (sheet volumes) ; Smaers.csv
# Outputs: Smaers_etal_2017_TableS1part1_comparison_report_from_R.csv
#          Smaers_etal_2017_TableS1part1_comparison_mismatches_from_R.csv

suppressPackageStartupMessages({
  library(readxl); library(readr); library(dplyr); library(tidyr); library(stringr)
})
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())
  if (interactive() && requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  setwd("/Users/crossmodal/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/_setwd_backup/Smaers_etal_2017/comparison")
}

snapshot_file     <- "../Smaers_etal_2017_TableS1part1_snapshot.xlsx"
snapshot_sheet    <- "volumes"
comparison_file   <- "Smaers.csv"
output_detail     <- "Smaers_etal_2017_TableS1part1_comparison_report_from_R.csv"
output_mismatches <- "Smaers_etal_2017_TableS1part1_comparison_mismatches_from_R.csv"
header_rows       <- 3L

# shared measures: snapshot column -> Smaers.csv column
csv_col <- c(
  prefrontal_gray         = "Prefrontal Gray",
  other_association_gray  = "Other cortical association areas Gray",
  frontal_motor_gray      = "Frontal motor Gray",
  primary_visual_white    = "Primary visual White Smaers",
  prefrontal_white        = "Prefrontal White",
  other_association_white = "Other cortical association areas White",
  frontal_motor_white     = "Frontal motor"
)
structures <- names(csv_col)

parse_value <- function(x) parse_number(as.character(x), na = c("", "-", "NA", "n.a.", "__"))
# genus+species key (drop subspecies, lowercase, spaces/underscores unified)
sp_key <- function(x) {
  x <- tolower(str_squish(str_replace_all(x, "_", " ")))
  vapply(str_split(x, " "), function(p) paste(head(p, 2), collapse = " "), character(1))
}

pos <- c("species_disp",
         "primary_visual_gray","prefrontal_gray","other_association_gray","frontal_motor_gray",
         "primary_visual_white","prefrontal_white","other_association_white","frontal_motor_white")
raw  <- read_excel(snapshot_file, sheet = snapshot_sheet, col_names = FALSE, col_types = "text")
sdat <- raw %>% slice(-(seq_len(header_rows)))
names(sdat)[seq_along(pos)] <- pos

snap <- sdat %>%
  filter(!is.na(species_disp), species_disp != "") %>%
  transmute(species_key = sp_key(species_disp), species_snapshot = str_squish(species_disp),
            prefrontal_gray_snap         = parse_value(prefrontal_gray),
            other_association_gray_snap  = parse_value(other_association_gray),
            frontal_motor_gray_snap      = parse_value(frontal_motor_gray),
            primary_visual_white_snap    = parse_value(primary_visual_white),
            prefrontal_white_snap        = parse_value(prefrontal_white),
            other_association_white_snap = parse_value(other_association_white),
            frontal_motor_white_snap     = parse_value(frontal_motor_white))

comp_raw <- read_csv(comparison_file, col_types = cols(.default = col_character()), na = c(""))
comp <- comp_raw %>%
  filter(!is.na(Species), Species != "") %>%
  transmute(species_key = sp_key(Species), species_csv = str_squish(Species),
            prefrontal_gray_csv         = parse_value(.data[[csv_col[["prefrontal_gray"]]]]),
            other_association_gray_csv  = parse_value(.data[[csv_col[["other_association_gray"]]]]),
            frontal_motor_gray_csv      = parse_value(.data[[csv_col[["frontal_motor_gray"]]]]),
            primary_visual_white_csv    = parse_value(.data[[csv_col[["primary_visual_white"]]]]),
            prefrontal_white_csv        = parse_value(.data[[csv_col[["prefrontal_white"]]]]),
            other_association_white_csv = parse_value(.data[[csv_col[["other_association_white"]]]]),
            frontal_motor_white_csv     = parse_value(.data[[csv_col[["frontal_motor_white"]]]]))

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
        " | csv-only: ", sum(report$status == "csv_only_not_in_snapshot"),
        "  [note: primary_visual_gray is snapshot-only; not in Smaers.csv]")
