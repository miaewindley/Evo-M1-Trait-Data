# Smaers_etal_2017_TableS1part2.R
#
# Smaers JB, Gomez-Robles A, Parks AN, Sherwood CC (2017), Current Biology 27:714-720,
# "Exceptional Evolutionary Expansion of Prefrontal Cortex in Great Apes and Humans."
# DOI 10.1016/j.cub.2017.01.020.  Supplemental Table S1 (file mmc1).  This is PART 2 of 2
# -- the "Brodmann data" SURFACE-AREA block only: 4 cortical regions (primary visual,
# prefrontal, other cortical association areas, frontal motor), 10 primate species.
# (Part 1 = the Smaers volume block; see Smaers_etal_2017_TableS1part1.R.)
#
# Provenance: surface areas are taken from Brodmann (1909) [S3]; only 9 of the 10 species
# carry the full set (Saimiri sciureus has primary visual only).  Units mm2 (as printed).
#
# Output comes from the snapshot only.
# Input  : Smaers_etal_2017_TableS1part2_snapshot.xlsx   sheet: surface_area
# Outputs: Smaers_etal_2017_TableS1part2.csv             one row per species (10)
#          <DOI>_TableS1_part2_surfacearea.tsv in __Public/comparative-data/

suppressPackageStartupMessages({
  library(readxl); library(readr); library(dplyr); library(stringr)
})
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())
  if (interactive() && requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  if (interactive() && requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  setwd("/Users/crossmodal/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/Smaers_etal_2017")
}
}

snapshot_file  <- "Smaers_etal_2017_TableS1part2_snapshot.xlsx"
snapshot_sheet <- "surface_area"
output_file    <- "Smaers_etal_2017_TableS1part2.csv"
header_rows    <- 3L

pos <- c("species_disp",
         "primary_visual_surface","prefrontal_surface","other_association_surface","frontal_motor_surface")
num <- function(x) parse_number(as.character(x), na = c("", "-", "NA", "n.a.", "__"))

raw <- read_excel(snapshot_file, sheet = snapshot_sheet, col_names = FALSE, col_types = "text")
dat <- raw %>% slice(-(seq_len(header_rows)))
names(dat)[seq_along(pos)] <- pos

final.dataframe <- dat %>%
  filter(!is.na(species_disp), species_disp != "") %>%
  transmute(
    species                   = str_replace_all(str_squish(species_disp), " ", "_"),
    primary_visual_surface    = num(primary_visual_surface),
    prefrontal_surface        = num(prefrontal_surface),
    other_association_surface = num(other_association_surface),
    frontal_motor_surface     = num(frontal_motor_surface),
    source                    = "Smaers_etal_2017"
  )

options(scipen = 999)

## ---- SAVE: local CSV + DOI-named TSV (named from __ReadMe.xlsx 'Item encoded') ----
item_name <- tryCatch(gsub("\\.R$", "", basename(rstudioapi::getActiveDocumentContext()$path)),
                      error = function(e) tools::file_path_sans_ext(output_file))
if (is.null(item_name) || !nzchar(item_name)) item_name <- tools::file_path_sans_ext(output_file)
write.csv(final.dataframe, file = paste0(item_name, ".csv"), row.names = FALSE)
message("Wrote ", item_name, ".csv  (", nrow(final.dataframe), " rows)")

readme_file <- "~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/__ReadMe.xlsx"
tsv_dir     <- "~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/__Public/comparative-data/"
filecodes    <- read_excel(readme_file, sheet = "Sheet1")
# __ReadMe 'Item name' is a formula that strips spaces & underscores from the Item
# number (e.g. "Table S1 part2 surface area" -> "...TableS1part2surfacearea"), so match
# on a separator-insensitive key rather than the literal file stem.
norm_key     <- function(x) tolower(gsub("[ _]", "", as.character(x)))
item_encoded <- filecodes$"Item encoded"[match(norm_key(item_name), norm_key(filecodes$"Item name"))]
if (is.na(item_encoded) || !nzchar(item_encoded)) {
  warning("No 'Item encoded' (DOI) for '", item_name, "' in __ReadMe.xlsx; TSV skipped.")
} else if (!dir.exists(path.expand(tsv_dir))) {
  warning("Shared folder not found: ", tsv_dir, "; TSV skipped.")
} else {
  write.table(final.dataframe, file = paste0(tsv_dir, item_encoded, ".tsv"), sep = "\t", row.names = FALSE)
  message("Wrote ", tsv_dir, item_encoded, ".tsv")
}
