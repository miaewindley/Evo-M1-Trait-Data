# Bauernfeind_etal_2013_Table1.R
#
# Preparation step. Turn the journal-faithful snapshot of Bauernfeind et al.
# (2013) Table 1 -- the per-INDIVIDUAL, shrinkage-corrected volumes of the LEFT
# insula and its subdivisions -- into a lean, analysis-ready CSV/TSV. Output
# comes from the snapshot only.
#
# Snapshot layout (matches the printed Table 1): row1 caption, row2 the unit
# banner ("Volume estimates of left insular subdivisions (cm3)"), row3 the column
# headers, then 43 individual rows (full species name on the first individual of
# each species, abbreviated -- "H. sapiens" -- thereafter; missing/absent values
# as en-dash), then three footnote rows (a/b/c). Volumes are in cm3, body mass in
# kg, brain mass in g, exactly as printed.
#
# THIS script reads past the 3 header rows, keeps the individual rows (drops the
# footnotes), carries the genus down to expand the abbreviated species names, and
# converts to the project units used in Bauernfeind_2013.csv: body kg -> g, brain
# g -> mg, all volumes cm3 -> mm3 (x1000). Because the table is left-insula
# only, the five insula/subdivision output columns are explicitly marked with
# the Barger-style _L side tag. One row per individual (43).
# Species means (and the two-Pongo-species merge the CSV uses) are a downstream
# aggregation -- see the comparison script -- not done here.
#
# Input  : Bauernfeind_etal_2013_Table1_snapshot.xlsx   sheet: Table1
# Outputs: Bauernfeind_etal_2013_Table1.csv             one row per individual (43)
#          <DOI>.tsv in __Public/comparative-data/        named from __ReadMe.xlsx

suppressPackageStartupMessages({
  library(readxl); library(readr); library(dplyr); library(tidyr); library(stringr)
})
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())
  if (interactive() && requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  if (interactive() && requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  setwd("/Users/crossmodal/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/Bauernfeind_etal_2013")
}
}

snapshot_file  <- "Bauernfeind_etal_2013_Table1_snapshot.xlsx"
snapshot_sheet <- "Table1"
output_file    <- "Bauernfeind_etal_2013_Table1.csv"
header_rows    <- 3L   # caption + unit banner + column headers; data from row 4

pos <- c("species_disp","individual","collection","section_thickness_mm","age","sex",
         "body_mass_kg","social_group_size","brain_mass_g","brain_volume_cm3",
         "granular_cm3","dysgranular_cm3","agranular_cm3","FI_cm3","total_insula_cm3")
num <- function(x) parse_number(as.character(x), na = c("", "-", "–", "—", "NA", "n.a.", "__", "e"))

raw <- read_excel(snapshot_file, sheet = snapshot_sheet, col_names = FALSE, col_types = "text")
dat <- raw %>% slice(-(seq_len(header_rows)))
names(dat)[seq_along(pos)] <- pos

# keep individual rows only (drop the 3 footnote rows: text in col A, no individual ID)
dat <- dat %>% filter(!is.na(individual), str_squish(individual) != "")

# expand abbreviated species: carry the most recent full genus down onto "H. sapiens" rows
dat <- dat %>%
  mutate(genus_tok = word(str_squish(species_disp), 1),
         full_genus = ifelse(str_detect(genus_tok, "\\.$"), NA_character_, genus_tok)) %>%
  fill(full_genus, .direction = "down") %>%
  mutate(Species_Bauernfeind2013 = ifelse(str_detect(genus_tok, "\\.$"),
            str_squish(paste(full_genus, word(str_squish(species_disp), 2, -1))),
            str_squish(species_disp)))

final.dataframe <- dat %>% transmute(
  Species_Bauernfeind2013,
  Individual           = str_squish(individual),
  Collection           = str_squish(collection),
  section_thickness_mm = num(section_thickness_mm),
  age                  = num(age),
  sex                  = str_squish(sex),
  body_mass_g          = num(body_mass_kg) * 1000,   # kg -> g
  social_group_size    = num(social_group_size),
  brain_mass_mg        = num(brain_mass_g) * 1000,   # g  -> mg
  brain_volume_mm3     = num(brain_volume_cm3) * 1000, # cm3 -> mm3

  # Table 1's unit banner says these are LEFT insular subdivisions. Mark only
  # the insula/subdivision measures with _L; brain_volume_mm3 is whole brain.
  granular_L_mm3       = num(granular_cm3)   * 1000,
  dysgranular_L_mm3    = num(dysgranular_cm3) * 1000,
  agranular_L_mm3      = num(agranular_cm3)  * 1000,
  FI_L_mm3             = num(FI_cm3)         * 1000,
  total_insula_L_mm3   = num(total_insula_cm3) * 1000)

options(scipen = 999)

## ---- SAVE: local CSV + DOI-named TSV ----
item_name <- tryCatch(gsub("\\.R$", "", basename(rstudioapi::getActiveDocumentContext()$path)),
                      error = function(e) tools::file_path_sans_ext(output_file))
if (is.null(item_name) || !nzchar(item_name)) item_name <- tools::file_path_sans_ext(output_file)
write.csv(final.dataframe, file = paste0(item_name, ".csv"), row.names = FALSE)
message("Wrote ", item_name, ".csv  (", nrow(final.dataframe), " individuals, ",
        dplyr::n_distinct(final.dataframe$Species_Bauernfeind2013), " species)")

readme_file <- "~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/__ReadMe.xlsx"
tsv_dir     <- "~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/__Public/comparative-data/"
item_encoded_fallback <- "10.1016%2Fj.jhevol.2012.12.003_Table1"

if (file.exists(path.expand(readme_file))) {
  filecodes    <- read_excel(readme_file, sheet = "Sheet1")
  item_encoded <- filecodes$"Item encoded"[match(item_name, filecodes$"Item name")]
} else {
  item_encoded <- item_encoded_fallback
  warning("__ReadMe.xlsx not found; using known DOI code for local TSV name: ", item_encoded)
}

if (is.na(item_encoded) || !nzchar(item_encoded)) {
  warning("No 'Item encoded' (DOI) for '", item_name, "' in __ReadMe.xlsx; TSV skipped.")
} else if (!dir.exists(path.expand(tsv_dir))) {
  warning("Shared folder not found: ", tsv_dir, "; TSV skipped (no local copy written).")
} else {
  write.table(final.dataframe, file = paste0(tsv_dir, item_encoded, ".tsv"), sep = "\t", row.names = FALSE)
  message("Wrote ", tsv_dir, item_encoded, ".tsv")
}
