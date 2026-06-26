# Matano_etal_1985_b_Table1.R
#
# Preparation step. Turn the journal-faithful snapshot of Matano, Stephan & Baron
# (1985), "Volume comparisons in the cerebellar complex of primates. I. Ventral
# pons" (Folia Primatol. 44:171-181, DOI 10.1159/000156211) Table I into a lean,
# analysis-ready CSV. Output comes from the snapshot only.
#
# (Folder/registry now consistent: this folder = registry sequence 'b' = the
# ventral-pons paper; the data token is Matano1985b throughout.)
#
# Snapshot layout (the volumes columns of the printed Table I): row1 caption, row2
# headers, row3 printed column numbers (1)-(5), then species rows in code order
# with grade header rows (Insectivora / Scandentia / Prosimians / Simians). Only
# the body-weight and ventral-pons-volume columns are transcribed; the printed
# size-index / ratio / %-of-brainstem columns are derived and recomputed
# downstream (and the 1985 scan's index columns are unreliable to OCR).
#
# Input  : Matano_etal_1985_b_Table1_snapshot.xlsx       sheet: Table1
# Outputs: Matano_etal_1985_b_Table1.csv                 one row per species (48)
#          <DOI>.tsv in __Public/comparative-data/         named from __ReadMe.xlsx

suppressPackageStartupMessages({
  library(readxl); library(readr); library(dplyr); library(stringr)
})
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())
  setwd("/Users/crossmodal/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/_setwd_backup/_setwd_backup/Matano_etal_1985_b")

snapshot_file  <- "Matano_etal_1985_b_Table1_snapshot.xlsx"
snapshot_sheet <- "Table1"
output_file    <- "Matano_etal_1985_b_Table1.csv"
header_rows    <- 3L

pos <- c("code","species_disp","n_raw","body_weight_g","ventral_pons_mm3")
num <- function(x) parse_number(as.character(x), na = c("", "-", "–", "—", "NA", "n.a.", "__"))

raw <- read_excel(snapshot_file, sheet = snapshot_sheet, col_names = FALSE, col_types = "text")
dat <- raw %>% slice(-(seq_len(header_rows)))
names(dat)[seq_along(pos)] <- pos

final.dataframe <- dat %>%
  filter(!is.na(num(ventral_pons_mm3))) %>%   # species rows = numeric VPo volume (drops grade headers)
  transmute(
    code                = as.integer(num(code)),
    Species_Matano1985b = str_squish(species_disp),
    n                   = as.integer(num(n_raw)),
    body_weight_g       = num(body_weight_g),
    ventral_pons_mm3    = num(ventral_pons_mm3)
  )

options(scipen = 999)

## ---- SAVE: local CSV + DOI-named TSV (standard registry lookup by Item name) ----
item_name <- tryCatch(gsub("\\.R$", "", basename(rstudioapi::getActiveDocumentContext()$path)),
                      error = function(e) tools::file_path_sans_ext(output_file))
if (is.null(item_name) || !nzchar(item_name)) item_name <- tools::file_path_sans_ext(output_file)
write.csv(final.dataframe, file = paste0(item_name, ".csv"), row.names = FALSE)
message("Wrote ", item_name, ".csv  (", nrow(final.dataframe), " species)")

readme_file <- "~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/__ReadMe.xlsx"
tsv_dir     <- "~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/__Public/comparative-data/"
filecodes    <- read_excel(readme_file, sheet = "Sheet1")
item_encoded <- filecodes$"Item encoded"[match(item_name, filecodes$"Item name")]
if (is.na(item_encoded) || !nzchar(item_encoded)) {
  warning("No 'Item encoded' for '", item_name, "' in __ReadMe.xlsx; TSV skipped.")
} else if (!dir.exists(path.expand(tsv_dir))) {
  warning("Shared folder not found: ", tsv_dir, "; TSV skipped.")
} else {
  write.table(final.dataframe, file = paste0(tsv_dir, item_encoded, ".tsv"), sep = "\t", row.names = FALSE)
  message("Wrote ", tsv_dir, item_encoded, ".tsv")
}
