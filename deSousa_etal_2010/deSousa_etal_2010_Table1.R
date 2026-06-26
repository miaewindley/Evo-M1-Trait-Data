# deSousa_etal_2010_Table1.R
# Preparation step. de Sousa, A. A., et al. (2010). Hominoid visual brain structure volumes... J Hum Evol 58(4),281-292.
# Turn the journal-faithful snapshot into a lean, analysis-ready CSV (values from
# the curated comparison CSV deSousa_2010.csv; volumes in mm3). Output from the snapshot only.
suppressPackageStartupMessages({ library(readxl); library(readr); library(dplyr); library(stringr) })
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())
  if (interactive() && requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  if (interactive() && requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  setwd("/Users/crossmodal/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/deSousa_etal_2010")
}
}
snapshot_file <- "deSousa_etal_2010_Table1_snapshot.xlsx"; snapshot_sheet <- "Table1"; output_file <- "deSousa_etal_2010_Table1.csv"
header_rows <- 2L   # row1 caption + row2 header
pos <- c("species_disp", "Neocortex_mm3", "Area_striata_grey_matter_mm3", "Corpus_geniculatum_laterale_mm3", "Total_brain_net_volume_mm3")
num <- function(x) parse_number(as.character(x), na = c("", "-", "NA", "n.a.", "__"))
raw <- read_excel(snapshot_file, sheet = snapshot_sheet, col_names = FALSE, col_types = "text")
dat <- raw %>% slice(-(seq_len(header_rows))); names(dat)[seq_along(pos)] <- pos
final.dataframe <- dat %>% filter(!is.na(Species_deSousa2010_disp := NULL) | TRUE) %>%   # keep species rows
  filter(!is.na(num(Neocortex_mm3))) %>%
  transmute(Species_deSousa2010 = str_squish(species_disp),
            Neocortex_mm3 = num(Neocortex_mm3), Area_striata_grey_matter_mm3 = num(Area_striata_grey_matter_mm3), Corpus_geniculatum_laterale_mm3 = num(Corpus_geniculatum_laterale_mm3), Total_brain_net_volume_mm3 = num(Total_brain_net_volume_mm3))
write.csv(final.dataframe, output_file, row.names = FALSE)
filecodes <- read_excel("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/__ReadMe.xlsx", sheet="Sheet1")
ie <- filecodes$"Item encoded"[match("deSousa_etal_2010_Table1", filecodes$"Item name")]
if (!is.na(ie) && nzchar(ie)) write.table(final.dataframe, paste0("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/__Public/comparative-data/", ie, ".tsv"), sep="\t", row.names=FALSE)
