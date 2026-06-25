# Bauernfeind_etal_2013_Table2.R
#
# Preparation step. Turn the journal-faithful snapshot of Bauernfeind et al. (2013)
# Table 2 -- the per-INDIVIDUAL, shrinkage-corrected volumes of the RIGHT insula and
# its subdivisions in humans and great apes -- into a lean, analysis-ready CSV/TSV.
# Output comes from the snapshot only.  This is the right-hemisphere counterpart of
# Table 1 (left); together they give whole-insula (both-hemisphere) volumes downstream
# (see __merging_volumes/volumes_compiled.R, Phase-4 hemisphere reconciliation).
#
# Snapshot layout (Bauernfeind_etal_2013_Table2_snapshot.xlsx, sheet Table2): a single
# header row (Species, Individual, Granular, Dysgranular, Agranular, FI, Total insula)
# then 15 individual rows.  Full binomial on the first individual of each species,
# abbreviated ("H. sapiens") thereafter.  Volumes are cm3, exactly as printed.
#
# THIS script expands the abbreviated species names (carry the genus down) and converts
# cm3 -> mm3 (x1000).  Because the table is the RIGHT insula, the five insula columns
# carry the Barger-style _R side tag.  One row per individual (15).
#
# Input  : Bauernfeind_etal_2013_Table2_snapshot.xlsx   sheet: Table2
# Outputs: Bauernfeind_etal_2013_Table2.csv             one row per individual (15)
#          <DOI>_Table2.tsv in __Public/comparative-data/

suppressPackageStartupMessages({
  library(readxl); library(readr); library(dplyr); library(tidyr); library(stringr)
})
setwd("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/Bauernfeind_etal_2013")
options(scipen = 999)

snapshot_file  <- "Bauernfeind_etal_2013_Table2_snapshot.xlsx"
snapshot_sheet <- "Table2"
output_file    <- "Bauernfeind_etal_2013_Table2.csv"

num <- function(x) parse_number(as.character(x), na = c("", "-", "\u2013", "\u2014", "NA", "n.a."))

raw <- read_excel(snapshot_file, sheet = snapshot_sheet, col_types = "text")
names(raw) <- c("species_disp", "individual", "granular_cm3", "dysgranular_cm3",
                "agranular_cm3", "FI_cm3", "total_insula_cm3")

# expand abbreviated species: carry the most recent full genus down onto "H. sapiens" rows
dat <- raw %>%
  filter(!is.na(individual), str_squish(individual) != "") %>%
  mutate(genus_tok  = word(str_squish(species_disp), 1),
         full_genus = ifelse(str_detect(genus_tok, "\\.$"), NA_character_, genus_tok)) %>%
  fill(full_genus, .direction = "down") %>%
  mutate(Species_Bauernfeind2013 = ifelse(str_detect(genus_tok, "\\.$"),
            str_squish(paste(full_genus, word(str_squish(species_disp), 2, -1))),
            str_squish(species_disp)))

final.dataframe <- dat %>% transmute(
  Species_Bauernfeind2013,
  Individual         = str_squish(individual),
  # Table 2 is the RIGHT insula; tag the five insula measures with _R. cm3 -> mm3.
  granular_R_mm3     = num(granular_cm3)     * 1000,
  dysgranular_R_mm3  = num(dysgranular_cm3)  * 1000,
  agranular_R_mm3    = num(agranular_cm3)    * 1000,
  FI_R_mm3           = num(FI_cm3)           * 1000,
  total_insula_R_mm3 = num(total_insula_cm3) * 1000)

write.csv(final.dataframe, output_file, row.names = FALSE)
message("Wrote ", output_file, "  (", nrow(final.dataframe), " individuals, ",
        dplyr::n_distinct(final.dataframe$Species_Bauernfeind2013), " species)")

## ---- also write the DOI-coded TSV to __Public/comparative-data/ ----
## Item-name "Bauernfeind_etal_2013_Table2" should be added to __ReadMe.xlsx (manually, to
## preserve its formula columns); until then fall back to the Table-1 DOI with a _Table2 tag.
item_name <- "Bauernfeind_etal_2013_Table2"
base      <- "~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data"
tsv_dir   <- file.path(base, "__Public/comparative-data")
enc_fallback <- "10.1016%2Fj.jhevol.2012.12.003_Table2"
enc <- tryCatch({
  fc <- readxl::read_excel(file.path(base, "__ReadMe.xlsx"), sheet = "Sheet1")
  e <- fc$"Item encoded"[match(item_name, fc$"Item name")]
  if (length(e) && !is.na(e) && nzchar(e)) e else enc_fallback
}, error = function(e) enc_fallback)
if (dir.exists(path.expand(tsv_dir))) {
  write.table(final.dataframe, file = file.path(tsv_dir, paste0(enc, ".tsv")),
              sep = "\t", row.names = FALSE)
  message("Wrote ", file.path(tsv_dir, paste0(enc, ".tsv")))
} else {
  warning("Shared folder not found; TSV skipped (no local copy written): ", paste0(enc, ".tsv"))
}
