# Frahm_etal_1998_Table1.R
# Preparation step. Frahm, H. D., Zilles, K., Schleicher, A., & Stephan, H. (1998). The size of the middle temporal area in primates. J Hirnforsch 39(1),45-54. PMID 9672110.
# Turn the journal-faithful snapshot into a lean, analysis-ready CSV (values from
# the curated comparison CSV Frahm_1998.csv; volumes in mm3). Output from the snapshot only.
suppressPackageStartupMessages({ library(readxl); library(readr); library(dplyr); library(stringr) })
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())
  if (interactive() && requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  if (interactive() && requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  setwd("/Users/crossmodal/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/Frahm_etal_1998")
}
}
snapshot_file <- "Frahm_etal_1998_Table1_snapshot.xlsx"; snapshot_sheet <- "Table1"; output_file <- "Frahm_etal_1998_Table1.csv"
header_rows <- 2L   # row1 caption + row2 header
pos <- c("species_disp", "n_raw", "Middle_temporal_visual_area_mm3", "Area_striata_grey_matter_mm3", "Corpus_geniculatum_laterale_mm3", "body_weight_g", "brain_weight_mg")
num <- function(x) parse_number(as.character(x), na = c("", "-", "NA", "n.a.", "__"))
raw <- read_excel(snapshot_file, sheet = snapshot_sheet, col_names = FALSE, col_types = "text")
dat <- raw %>% slice(-(seq_len(header_rows))); names(dat)[seq_along(pos)] <- pos
final.dataframe <- dat %>% filter(!is.na(Species_Frahm98_disp := NULL) | TRUE) %>%   # keep species rows
  filter(!is.na(num(Middle_temporal_visual_area_mm3))) %>%
  transmute(Species_Frahm98 = str_squish(species_disp), n = as.integer(num(n_raw)),
            Middle_temporal_visual_area_mm3 = num(Middle_temporal_visual_area_mm3), Area_striata_grey_matter_mm3 = num(Area_striata_grey_matter_mm3), Corpus_geniculatum_laterale_mm3 = num(Corpus_geniculatum_laterale_mm3), body_weight_g = num(body_weight_g), brain_weight_mg = num(brain_weight_mg))
write.csv(final.dataframe, output_file, row.names = FALSE)
filecodes <- read_excel("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/__ReadMe.xlsx", sheet="Sheet1")
ie <- filecodes$"Item encoded"[match("Frahm_etal_1998_Table1", filecodes$"Item name")]
if (!is.na(ie) && nzchar(ie)) write.table(final.dataframe, paste0("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/__Public/comparative-data/", ie, ".tsv"), sep="\t", row.names=FALSE)
