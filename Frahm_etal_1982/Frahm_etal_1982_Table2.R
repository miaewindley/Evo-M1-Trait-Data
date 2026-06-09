# Frahm_etal_1982_Table2.R
#
# Preparation step. Turn the journal-faithful snapshot of Frahm & Stephan (1982,
# Part I, neocortex) Table 2 -- the neocortex volumes -- into a lean, analysis-
# ready CSV. Output comes from the snapshot only.
#
# Snapshot layout (matches the printed Table 2): row 1 caption, row 2 column
# headers, row 3 the printed column numbers (1)-(7), then the species rows in
# taxonomic order with blank rows separating groups. One leading "species"
# column (n > 1 shown in parentheses, e.g. "Tupaia glis (2)") followed by the 7
# measures. THIS script reads past the header, keeps the species rows (skipping
# the blank group separators), and splits the parenthetical n off the name.
#
# Size indices are NOT recomputed here: they are a deterministic function of the
# volumes and BODY WEIGHTS (external to this volumes table), via reference lines
# of fixed, structure-specific slope through the basal-Insectivora centroid --
# total 0.67, white matter 0.86, grey matter 0.63, lamina 1 0.65, laminae 2-6
# 0.62 (Frahm & Stephan 1982, Methods). Recompute downstream where body weights
# (Stephan et al. 1981) are joined; the paper's Table 1 gives the total-neocortex
# index for validation.
#
# Input  : Frahm_etal_1982_Table2_snapshot.xlsx       sheet: Table2
# Outputs: Frahm_etal_1982_Table2.csv                 one row per species (38)
#          <DOI/PMID>.tsv in __Public/comparative-data/  named from __ReadMe.xlsx

suppressPackageStartupMessages({
  library(readxl); library(readr); library(dplyr); library(stringr)
})
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())
  setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

snapshot_file  <- "Frahm_etal_1982_Table2_snapshot.xlsx"
snapshot_sheet <- "Table2"
output_file    <- "Frahm_etal_1982_Table2.csv"
header_rows    <- 3L   # row1 caption + row2 headers + row3 column numbers; data (and blank separators) from row 4

pos <- c("species_disp","total_neocortex","white_matter","white_pct_neocortex",
         "grey_matter","lamina_1","lamina_1_pct_grey","laminae_2_6")
num <- function(x) parse_number(as.character(x), na = c("", "-", "NA", "n.a.", "__"))

raw <- read_excel(snapshot_file, sheet = snapshot_sheet, col_names = FALSE, col_types = "text")
dat <- raw %>% slice(-(seq_len(header_rows)))
names(dat)[seq_along(pos)] <- pos

final.dataframe <- dat %>%
  filter(!is.na(species_disp), str_squish(species_disp) != "", !is.na(num(total_neocortex))) %>%
  transmute(
    Species_Frahm1982   = str_squish(str_remove(species_disp, "\\s*\\(\\d+\\)\\s*$")),  # drop the "(n)" suffix
    n                   = ifelse(str_detect(species_disp, "\\((\\d+)\\)\\s*$"),
                                 as.integer(str_match(species_disp, "\\((\\d+)\\)\\s*$")[, 2]), 1L),
    total_neocortex_mm3 = num(total_neocortex),
    white_matter_mm3    = num(white_matter),
    white_pct_neocortex = num(white_pct_neocortex),
    grey_matter_mm3     = num(grey_matter),
    lamina_1_mm3        = num(lamina_1),
    lamina_1_pct_grey   = num(lamina_1_pct_grey),
    laminae_2_6_mm3     = num(laminae_2_6)
  )

options(scipen = 999)

## ---- SAVE: local CSV + DOI/PMID-named TSV ----
item_name <- tryCatch(gsub("\\.R$", "", basename(rstudioapi::getActiveDocumentContext()$path)),
                      error = function(e) tools::file_path_sans_ext(output_file))
if (is.null(item_name) || !nzchar(item_name)) item_name <- tools::file_path_sans_ext(output_file)
write.csv(final.dataframe, file = paste0(item_name, ".csv"), row.names = FALSE)
message("Wrote ", item_name, ".csv  (", nrow(final.dataframe), " rows)")

readme_file <- "~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/__ReadMe.xlsx"
tsv_dir     <- "~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/__Public/comparative-data/"
filecodes    <- read_excel(readme_file, sheet = "Sheet1")
item_encoded <- filecodes$"Item encoded"[match(item_name, filecodes$"Item name")]
if (is.na(item_encoded) || !nzchar(item_encoded)) {
  warning("No 'Item encoded' (DOI) for '", item_name, "' in __ReadMe.xlsx; TSV skipped.")
} else if (!dir.exists(path.expand(tsv_dir))) {
  warning("Shared folder not found: ", tsv_dir, "; TSV skipped.")
} else {
  write.table(final.dataframe, file = paste0(tsv_dir, item_encoded, ".tsv"), sep = "\t", row.names = FALSE)
  message("Wrote ", tsv_dir, item_encoded, ".tsv")
}
