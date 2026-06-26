# Stephan_etal_1987_Table1.R
# Preparation step. Stephan, H., Frahm, H. D., & Baron, G. (1987). Comparison of brain structure volumes... amygdaloid complex. (J. Hirnforsch.)
# Turn the journal-faithful snapshot into a lean, analysis-ready CSV (values from
# the curated comparison CSV Stephan1987_AMY_vs_Barger2007_AC.csv; volumes in mm3). Output from the snapshot only.
suppressPackageStartupMessages({ library(readxl); library(readr); library(dplyr); library(stringr) })
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())
  if (interactive() && requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  setwd("/Users/crossmodal/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/_setwd_backup/Stephan_etal_1987")
}
snapshot_file <- "Stephan_etal_1987_Table1_snapshot.xlsx"; snapshot_sheet <- "Table1"; output_file <- "Stephan_etal_1987_Table1.csv"
header_rows <- 2L   # row1 caption + row2 header
pos <- c("species_disp", "Amygdala_mm3", "Complexus_centromedialis_mm3", "Complexus_corticobasolateralis_mm3", "Nucleus_amygdalae_basalis_pars_magnocellularis_mm3", "Nucleus_tractus_olfactorius_mm3")
num <- function(x) parse_number(as.character(x), na = c("", "-", "NA", "n.a.", "__"))
raw <- read_excel(snapshot_file, sheet = snapshot_sheet, col_names = FALSE, col_types = "text")
dat <- raw %>% slice(-(seq_len(header_rows))); names(dat)[seq_along(pos)] <- pos
final.dataframe <- dat %>% filter(!is.na(Species_Stephan1987_disp := NULL) | TRUE) %>%   # keep species rows
  filter(!is.na(num(Amygdala_mm3))) %>%
  transmute(Species_Stephan1987 = str_squish(species_disp),
            Amygdala_mm3 = num(Amygdala_mm3), Complexus_centromedialis_mm3 = num(Complexus_centromedialis_mm3), Complexus_corticobasolateralis_mm3 = num(Complexus_corticobasolateralis_mm3), Nucleus_amygdalae_basalis_pars_magnocellularis_mm3 = num(Nucleus_amygdalae_basalis_pars_magnocellularis_mm3), Nucleus_tractus_olfactorius_mm3 = num(Nucleus_tractus_olfactorius_mm3))
write.csv(final.dataframe, output_file, row.names = FALSE)
filecodes <- read_excel("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/__ReadMe.xlsx", sheet="Sheet1")
ie <- filecodes$"Item encoded"[match("Stephan_etal_1987_Table1", filecodes$"Item name")]
if (!is.na(ie) && nzchar(ie)) write.table(final.dataframe, paste0("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/__Public/comparative-data/", ie, ".tsv"), sep="\t", row.names=FALSE)
