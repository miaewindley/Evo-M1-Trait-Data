# Baron_etal_1988_Table1.R
#
# Snapshot preparation. Turn the faithful snapshot of Baron et al. 1988 Table 1
# (vestibular nuclear complex volumes) into a lean, analysis-ready CSV. Output
# comes from the snapshot only -- no crosswalk, no comparison files. Structure
# codes/units are documented in reference_tables/Baron_etal_1988_definitions.csv.
#
# Input
#   Baron_etal_1988_Table1_snapshot.xlsx        sheet: Table1_snapshot
# Outputs
#   Baron_etal_1988_Table1.csv                  one row per species
#   <DOI>.tsv in __Public/comparative-data/     DOI-named copy (from __ReadMe.xlsx)

suppressPackageStartupMessages({
  library(readxl); library(readr); library(dplyr); library(tidyr); library(stringr)
})
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())
  if (interactive() && requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  setwd("/Users/crossmodal/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/_setwd_backup/Baron_etal_1988")
}

snapshot_file  <- "Baron_etal_1988_Table1_snapshot.xlsx"
snapshot_sheet <- "Table1_snapshot"
output_file    <- "Baron_etal_1988_Table1.csv"
structures     <- c("VC", "VI", "VL", "VM", "VS")

read_snapshot <- function(path, sheet) {
  raw <- read_excel(path, sheet = sheet, col_names = FALSE, col_types = "text", na = c(""))
  header <- as.character(unlist(raw[2, ], use.names = FALSE))
  blank <- is.na(header) | header == ""; header[blank] <- paste0("blank_", which(blank))
  dat <- raw[-c(1, 2), , drop = FALSE]; names(dat) <- header; dat
}
parse_value <- function(x) parse_number(x, na = c("", "-", "NA", "n.a.", "__"))

final.dataframe <- read_snapshot(snapshot_file, snapshot_sheet) %>%
  rename(Species_Baron1988 = `species name`) %>%
  filter(!is.na(Species_Baron1988)) %>%
  transmute(Species_Baron1988, across(all_of(structures), parse_value))

options(scipen = 999)

## ---- SAVE: local CSV + DOI-named TSV ----
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
