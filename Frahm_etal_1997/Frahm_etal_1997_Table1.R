# Frahm_etal_1997_Table1.R
# Preparation step. Frahm, H. D., Rehkamper, G., & Nevo, E. (1997). Brain structure volumes in Spalax ehrenbergi... J Hirnforsch 38(2),209-222. PMID 9176733.
# Turn the journal-faithful snapshot into a lean, analysis-ready CSV (values from
# the curated comparison CSV Frahm_1997.csv; volumes in mm3). Output from the snapshot only.
suppressPackageStartupMessages({ library(readxl); library(readr); library(dplyr); library(stringr) })
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())
  if (interactive() && requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  if (interactive() && requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  setwd("/Users/crossmodal/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/Frahm_etal_1997")
}
}
snapshot_file <- "Frahm_etal_1997_Table1_snapshot.xlsx"; snapshot_sheet <- "Table1"; output_file <- "Frahm_etal_1997_Table1.csv"
header_rows <- 2L   # row1 caption + row2 header
pos <- c("species_disp", "Cerebellum_mm3", "Diencephalon_mm3", "Telencephalon_mm3", "Bulbus_olfactorius_mm3", "Septum_mm3", "Striatum_mm3", "Schizo_cortex_mm3", "Hippocampus_mm3", "Neocortex_mm3", "Palaeocortex_mm3", "Amygdala_mm3")
num <- function(x) parse_number(as.character(x), na = c("", "-", "NA", "n.a.", "__"))
raw <- read_excel(snapshot_file, sheet = snapshot_sheet, col_names = FALSE, col_types = "text")
dat <- raw %>% slice(-(seq_len(header_rows))); names(dat)[seq_along(pos)] <- pos
final.dataframe <- dat %>% filter(!is.na(Species_Frahm1997_disp := NULL) | TRUE) %>%   # keep species rows
  filter(!is.na(num(Cerebellum_mm3))) %>%
  transmute(Species_Frahm1997 = str_squish(species_disp),
            Cerebellum_mm3 = num(Cerebellum_mm3), Diencephalon_mm3 = num(Diencephalon_mm3), Telencephalon_mm3 = num(Telencephalon_mm3), Bulbus_olfactorius_mm3 = num(Bulbus_olfactorius_mm3), Septum_mm3 = num(Septum_mm3), Striatum_mm3 = num(Striatum_mm3), Schizo_cortex_mm3 = num(Schizo_cortex_mm3), Hippocampus_mm3 = num(Hippocampus_mm3), Neocortex_mm3 = num(Neocortex_mm3), Palaeocortex_mm3 = num(Palaeocortex_mm3), Amygdala_mm3 = num(Amygdala_mm3))
write.csv(final.dataframe, output_file, row.names = FALSE)
filecodes <- read_excel("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/__ReadMe.xlsx", sheet="Sheet1")
ie <- filecodes$"Item encoded"[match("Frahm_etal_1997_Table1", filecodes$"Item name")]
if (!is.na(ie) && nzchar(ie)) write.table(final.dataframe, paste0("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/__Public/comparative-data/", ie, ".tsv"), sep="\t", row.names=FALSE)
