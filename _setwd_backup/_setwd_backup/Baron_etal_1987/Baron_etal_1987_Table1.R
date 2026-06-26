# Baron_etal_1987_Table1.R
#
# Purpose
#   Snapshot preparation. Turn the faithful snapshot of Baron et al. 1987
#   Table 1 (paleocortical / olfactory structures) into a lean, analysis-ready
#   CSV. Everything in the output comes from the paper via the snapshot only --
#   no crosswalk, no comparison files. Structure codes and units are documented
#   in reference_tables/Baron_etal_1987_definitions.csv, not in the data.
#
# Input
#   Baron_etal_1987_Table1_snapshot.xlsx        sheet: Table1_snapshot
#
# Outputs
#   Baron_etal_1987_Table1.csv                  one row per species (89 rows)
#   <DOI>.tsv in __Public/comparative-data/     tab-separated copy named by the
#                                               item's encoded DOI (from __ReadMe.xlsx)

suppressPackageStartupMessages({
  library(readxl)
  library(readr)
  library(dplyr)
  library(tidyr)
  library(stringr)
})

# Run from this script's own folder (RStudio), so the relative paths resolve.
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  setwd("/Users/crossmodal/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/_setwd_backup/_setwd_backup/Baron_etal_1987")
}

snapshot_file  <- "Baron_etal_1987_Table1_snapshot.xlsx"
snapshot_sheet <- "Table1_snapshot"
output_file    <- "Baron_etal_1987_Table1.csv"

structures <- c("BOL", "RB", "PRPI", "TOL", "TRL", "COA", "SIN")

# ---- helpers ---------------------------------------------------------------

read_snapshot <- function(path, sheet) {
  raw <- read_excel(path, sheet = sheet, col_names = FALSE, col_types = "text", na = c(""))
  header <- as.character(unlist(raw[2, ], use.names = FALSE))
  blank <- is.na(header) | header == ""
  header[blank] <- paste0("blank_", which(blank))
  dat <- raw[-c(1, 2), , drop = FALSE]
  names(dat) <- header
  dat
}
parse_value <- function(x) parse_number(x, na = c("", "-", "NA", "n.a.", "__"))

# ---- snapshot: the 89 species rows (snapshot only) -------------------------

final.dataframe <- read_snapshot(snapshot_file, snapshot_sheet) %>%
  rename(Species_Baron1987 = `species name`) %>%
  filter(!is.na(Species_Baron1987)) %>%               # drops group + footnote rows
  transmute(Species_Baron1987,
            across(all_of(structures), parse_value))

options(scipen = 999)

## ---- SAVE: local CSV + DOI-named TSV in the shared database folder --------
item_name <- tryCatch(
  gsub("\\.R$", "", basename(rstudioapi::getActiveDocumentContext()$path)),
  error = function(e) tools::file_path_sans_ext(output_file)
)
if (is.null(item_name) || !nzchar(item_name)) item_name <- tools::file_path_sans_ext(output_file)

write.csv(final.dataframe, file = paste0(item_name, ".csv"), row.names = FALSE)
message("Wrote ", item_name, ".csv  (", nrow(final.dataframe), " rows)")

readme_file <- "~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/__ReadMe.xlsx"
tsv_dir     <- "~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/__Public/comparative-data/"
filecodes    <- read_excel(readme_file, sheet = "Sheet1")
item_encoded <- filecodes$"Item encoded"[match(item_name, filecodes$"Item name")]

if (is.na(item_encoded) || !nzchar(item_encoded)) {
  warning("No 'Item encoded' (DOI) found for '", item_name, "' in __ReadMe.xlsx; TSV copy skipped.")
} else if (!dir.exists(path.expand(tsv_dir))) {
  warning("Shared folder not found: ", tsv_dir, "; TSV copy skipped.")
} else {
  write.table(final.dataframe, file = paste0(tsv_dir, item_encoded, ".tsv"),
              sep = "\t", row.names = FALSE)
  message("Wrote ", tsv_dir, item_encoded, ".tsv")
}
