# Frahm_etal_1982_Table2.R
#
# Preparation step. Turn the journal-faithful snapshot of Frahm & Stephan (1982,
# Part I, neocortex) Table 2 -- the neocortex volumes -- into a lean, analysis-
# ready CSV. Output comes from the snapshot only.
#
# The snapshot looks like the printed Table 2: a multi-row journal header, the
# taxonomic hierarchy spread over three indent columns (group / family /
# species), superscripts on the species names, interleaved group / subtotal /
# Mean rows. THIS script does the cleaning the snapshot leaves undone: read past
# the header, name columns by position, keep the species rows (species name +
# numeric volume), carry group/family down, and turn the name superscripts into
# former_name_ref + former_name.
#
# Size indices are NOT recomputed here: they are a deterministic function of the
# volumes and BODY WEIGHTS (external to this volumes table), via reference lines
# of fixed slope through the basal-Insectivora centroid -- total 0.67, white
# matter 0.86, grey matter 0.63, lamina 1 0.65, laminae 2-6 0.62 (Frahm & Stephan
# 1982, Methods). Recompute them in the downstream analysis, where body weights
# (Stephan et al. 1981) are joined in.
#
# Input  : Frahm_etal_1982_Table2_snapshot.xlsx       sheet: Table2
# Outputs: Frahm_etal_1982_Table2.csv                 one row per species (39)
#          <DOI/PMID>.tsv in __Public/comparative-data/  named from __ReadMe.xlsx

suppressPackageStartupMessages({
  library(readxl); library(readr); library(dplyr); library(tidyr); library(stringr)
})
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())
  setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

snapshot_file  <- "Frahm_etal_1982_Table2_snapshot.xlsx"
snapshot_sheet <- "Table2"
output_file    <- "Frahm_etal_1982_Table2.csv"
header_rows    <- 4L   # row1 caption + rows2-3 header tiers + row4 column numbers; data from row 5

pos <- c("group_raw","family_raw","species_disp","n_raw","total_neocortex","white_matter",
  "white_pct_neocortex","grey_matter","lamina_1","lamina_1_pct_grey","laminae_2_6")
num <- function(x) parse_number(as.character(x), na = c("", "-", "NA", "n.a.", "__"))

sup_to_digit <- c("¹"="1","²"="2","³"="3","⁴"="4","⁵"="5","⁶"="6","⁷"="7","⁸"="8","⁹"="9","⁰"="0")
sup_class    <- "[¹²³⁴⁵⁶⁷⁸⁹⁰]"
former_name_legend <- c("1"="Aethechinus algirus","2"="Crocidura occidentalis","3"="Nesogale dobsoni",
  "4"="Nesogale talazaci","5"="Chlorotalpa stuhlmanni","6"="Lemur fulvus","7"="Lemur variegatus",
  "8"="Galago crassicaudatus","9"="Galago demidovii","10"="Saguinus tamarin","11"="Cercopithecus talapoin")
extract_ref <- function(x) { m <- str_extract_all(x, sup_class)[[1]]
  if (length(m) == 0) NA_character_ else paste(sup_to_digit[m], collapse = "") }
strip_sup <- function(x) str_squish(str_remove_all(x, sup_class))

raw <- read_excel(snapshot_file, sheet = snapshot_sheet, col_names = FALSE, col_types = "text")
dat <- raw %>% slice(-(seq_len(header_rows)))
names(dat)[seq_along(pos)] <- pos

dat <- dat %>%
  mutate(
    is_grade = !is.na(group_raw) & !str_detect(group_raw, "^Mean"),
    grade_h  = if_else(is_grade, str_squish(group_raw), NA_character_),
    family_h = if_else(!is.na(family_raw) & !str_detect(family_raw, "^n ?="), str_squish(family_raw), NA_character_),
    .block   = cumsum(replace_na(is_grade, FALSE))
  ) %>%
  fill(grade_h, .direction = "down") %>%
  group_by(.block) %>% fill(family_h, .direction = "down") %>% ungroup()

final.dataframe <- dat %>%
  filter(!is.na(species_disp), species_disp != "", !is.na(num(total_neocortex))) %>%
  transmute(
    grade                = grade_h,
    family               = if_else(grade_h %in% c("Progressive Insectivora","Macroscelidea","Scandentia"),
                                   NA_character_, family_h),
    Species_Frahm1982    = strip_sup(species_disp),
    former_name_ref      = vapply(species_disp, extract_ref, character(1), USE.NAMES = FALSE),
    former_name          = unname(former_name_legend[former_name_ref]),
    n                    = as.integer(num(n_raw)),
    total_neocortex_mm3  = num(total_neocortex),
    white_matter_mm3     = num(white_matter),
    white_pct_neocortex  = num(white_pct_neocortex),
    grey_matter_mm3      = num(grey_matter),
    lamina_1_mm3         = num(lamina_1),
    lamina_1_pct_grey    = num(lamina_1_pct_grey),
    laminae_2_6_mm3      = num(laminae_2_6)
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
