# Stephan_etal_1982_Table1.R
#
# Preparation step. Turn the journal-faithful snapshot of Stephan, Baron & Frahm
# (1982) Table 1 (accessory olfactory bulb, AOB) into a lean, analysis-ready CSV.
#
# The snapshot is built to look like the printed table: a multi-row journal
# header, the taxonomic hierarchy spread over three indent columns
# (group / family / species), superscripts on the species names, interleaved
# group / subtotal / Mean rows, and footnotes. THIS script does the cleaning the
# snapshot deliberately leaves undone:
#   * read past the multi-row header (data begin on row 6) and give the columns
#     R-friendly names by position;
#   * keep the 61 species rows (the only rows with a species name AND a numeric
#     volume) and drop the group / family / subtotal / Mean / footnote rows;
#   * carry the grade (group) and family down onto each species row;
#   * turn the name superscripts into former_name_ref + former_name and a clean
#     binomial; split the n marker off into n_note.
# Output comes from the snapshot only -- no crosswalk, no comparison files.
# Column meanings/units: reference_tables/Stephan_etal_1982_definitions.csv.
#
# Input  : Stephan_etal_1982_Table1_snapshot.xlsx       sheet: Table1
# Outputs: Stephan_etal_1982_Table1.csv                 one row per species (61)
#          <DOI/PMID>.tsv in __Public/comparative-data/  named from __ReadMe.xlsx

suppressPackageStartupMessages({
  library(readxl); library(readr); library(dplyr); library(tidyr); library(stringr)
})
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())
  setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

snapshot_file  <- "Stephan_etal_1982_Table1_snapshot.xlsx"
snapshot_sheet <- "Table1"
output_file    <- "Stephan_etal_1982_Table1.csv"
header_rows    <- 5L   # row 1 caption + rows 2-5 multi-tier header; data start on row 6

col_names_pos <- c("group_raw","family_raw","species_disp","n_raw","volume","SEM_pct","size_index",
  "permille_net_brain","permille_MOB","AOB_layer_1_2","AOB_layer_3_5","AOB_layer_6",
  "pct_AOB_1_2","pct_AOB_3_5","pct_AOB_6","size_index_1_2","size_index_3_5","size_index_6")

num <- function(x) parse_number(as.character(x), na = c("", "-", "NA", "n.a.", "__"))

# --- superscript -> former-name machinery (the snapshot keeps journal superscripts) ---
sup_to_digit <- c("¹"="1","²"="2","³"="3","⁴"="4","⁵"="5",
                  "⁶"="6","⁷"="7","⁸"="8","⁹"="9","⁰"="0")
sup_class    <- "[¹²³⁴⁵⁶⁷⁸⁹⁰]"
former_name_legend <- c("1"="Aethechinus algirus","2"="Crocidura occidentalis","3"="Nesogale dobsoni",
  "4"="Nesogale talazaci","5"="Chlorotalpa stuhlmanni","6"="Rhynchocyon stuhlmanni","7"="Lemur fulvus",
  "8"="Lemur variegatus","9"="Galago crassicaudatus","10"="Galago demidovii","11"="Saguinus tamarin")
extract_ref <- function(x) {
  m <- str_extract_all(x, sup_class)[[1]]
  if (length(m) == 0) NA_character_ else paste(sup_to_digit[m], collapse = "")
}
strip_sup <- function(x) str_squish(str_remove_all(x, sup_class))

raw <- read_excel(snapshot_file, sheet = snapshot_sheet, col_names = FALSE, col_types = "text")
dat <- raw %>% slice(-(seq_len(header_rows)))
names(dat)[seq_along(col_names_pos)] <- col_names_pos

# carry grade (group) and family onto every row; family resets at each grade
dat <- dat %>%
  mutate(
    is_grade = !is.na(group_raw) & !str_detect(group_raw, "^Mean"),
    grade_h  = if_else(is_grade, str_squish(str_remove(group_raw, "\\s*§")), NA_character_),
    family_h = if_else(!is.na(family_raw) & !str_detect(family_raw, "^n ?="),
                       str_squish(family_raw), NA_character_),
    .block   = cumsum(replace_na(is_grade, FALSE))
  ) %>%
  fill(grade_h, .direction = "down") %>%
  group_by(.block) %>% fill(family_h, .direction = "down") %>% ungroup()

final.dataframe <- dat %>%
  filter(!is.na(species_disp), species_disp != "", !is.na(num(volume))) %>%   # 61 species rows
  transmute(
    grade               = grade_h,
    family              = family_h,
    Species_Stephan1982 = strip_sup(species_disp),
    former_name_ref     = vapply(species_disp, extract_ref, character(1), USE.NAMES = FALSE),
    former_name         = unname(former_name_legend[former_name_ref]),
    n_note              = str_extract(n_raw, "[*•¥]"),
    n                   = as.integer(num(n_raw)),
    AOB_volume_mm3      = num(volume),
    SEM_pct             = num(SEM_pct),
    size_index          = num(size_index),
    permille_net_brain  = num(permille_net_brain),
    permille_MOB        = num(permille_MOB),
    AOB_layer_1_2_mm3   = num(AOB_layer_1_2),
    AOB_layer_3_5_mm3   = num(AOB_layer_3_5),
    AOB_layer_6_mm3     = num(AOB_layer_6),
    pct_AOB_1_2         = num(pct_AOB_1_2),
    pct_AOB_3_5         = num(pct_AOB_3_5),
    pct_AOB_6           = num(pct_AOB_6),
    size_index_1_2      = num(size_index_1_2),
    size_index_3_5      = num(size_index_3_5),
    size_index_6        = num(size_index_6)
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
