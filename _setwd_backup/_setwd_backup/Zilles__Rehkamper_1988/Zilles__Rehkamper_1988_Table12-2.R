# Zilles__Rehkamper_1988_Table12-2.R
#
# Preparation step. Turn the journal-faithful snapshot of Zilles & Rehkamper
# (1988) Table 12-2 -- the fresh volumes of the brain components of the ORANG-
# UTAN (Pongo) and their percentage of total brain volume -- into a lean,
# analysis-ready CSV. Output comes from the snapshot only.
#
# Layout note (this table is NOT the usual species-as-rows table): Table 12-2 is
# a SINGLE-SPECIMEN table for Pongo with the brain STRUCTURES down the rows and
# two value columns (Fresh Volume in cc3 = cm3, and percentage of total brain
# volume). The snapshot keeps that printed orientation, the printed indentation
# of sub-components (e.g. White matter under Neocortex), the caption and the
# "excluding ventricles and nerves" footnote. There are no species-name
# superscripts to translate (the single "1" superscript is the footnote marker
# on the percentage header).
#
# THIS script reads past the caption+header (data from row 3), drops the footnote
# row (no numeric volume), squishes the structure label (removing the indentation
# the snapshot uses for the printed sub-rows), converts the printed cc3 volumes to
# the project unit mm3 (x1000), and writes one row per structure for Pongo.
#
# Input  : Zilles__Rehkamper_1988_Table12-2_snapshot.xlsx   sheet: Table12-2
# Outputs: Zilles__Rehkamper_1988_Table12-2.csv             one row per structure (18)
#          <DOI/PMID>.tsv in __Public/comparative-data/      named from __ReadMe.xlsx

suppressPackageStartupMessages({
  library(readxl); library(readr); library(dplyr); library(stringr)
})
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())
  setwd("/Users/crossmodal/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/_setwd_backup/_setwd_backup/Zilles__Rehkamper_1988")

snapshot_file  <- "Zilles__Rehkamper_1988_Table12-2_snapshot.xlsx"
snapshot_sheet <- "Table12-2"
output_file    <- "Zilles__Rehkamper_1988_Table12-2.csv"
header_rows    <- 2L   # row1 caption + row2 header; data (and the footnote) from row 3

pos <- c("structure_disp","fresh_volume_cc3","pct_total_brain")
num <- function(x) parse_number(as.character(x), na = c("", "-", "NA", "n.a.", "__"))
sup_class <- "[¹²³⁴⁵⁶⁷⁸⁹⁰]"

raw <- read_excel(snapshot_file, sheet = snapshot_sheet, col_names = FALSE, col_types = "text")
dat <- raw %>% slice(-(seq_len(header_rows)))
names(dat)[seq_along(pos)] <- pos

final.dataframe <- dat %>%
  filter(!is.na(structure_disp), !is.na(num(fresh_volume_cc3))) %>%   # structure rows = numeric volume (drops footnote)
  transmute(
    Species_Zilles1988 = "Pongo sp.",
    structure          = str_squish(str_remove_all(structure_disp, sup_class)),  # squish removes the printed indentation
    fresh_volume_cc3   = num(fresh_volume_cc3),
    volume_mm3         = num(fresh_volume_cc3) * 1000,                # cc3 (=cm3) -> mm3 (project unit)
    pct_total_brain    = num(pct_total_brain)
  )

options(scipen = 999)

## ---- SAVE: local CSV + DOI/PMID-named TSV ----
# The on-disk files follow the folder name (ASCII "Zilles__Rehkamper"); the
# __ReadMe.xlsx registry Item name uses the umlaut + single underscore, so we set
# the registry key explicitly for the Item-encoded (DOI/ISBN) lookup.
item_name          <- tools::file_path_sans_ext(output_file)            # Zilles__Rehkamper_1988_Table12-2
registry_item_name <- "Zilles_Rehkämper_1988_Table12-2"                  # as printed in __ReadMe.xlsx (Item name)
write.csv(final.dataframe, file = paste0(item_name, ".csv"), row.names = FALSE)
message("Wrote ", item_name, ".csv  (", nrow(final.dataframe), " rows)")

readme_file <- "~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/__ReadMe.xlsx"
tsv_dir     <- "~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/__Public/comparative-data/"
filecodes    <- read_excel(readme_file, sheet = "Sheet1")
item_encoded <- filecodes$"Item encoded"[match(registry_item_name, filecodes$"Item name")]
if (is.na(item_encoded) || !nzchar(item_encoded)) {
  warning("No 'Item encoded' (DOI/ISBN) for '", registry_item_name, "' in __ReadMe.xlsx; TSV skipped.")
} else if (!dir.exists(path.expand(tsv_dir))) {
  warning("Shared folder not found: ", tsv_dir, "; TSV skipped.")
} else {
  write.table(final.dataframe, file = paste0(tsv_dir, item_encoded, ".tsv"), sep = "\t", row.names = FALSE)
  message("Wrote ", tsv_dir, item_encoded, ".tsv")
}
