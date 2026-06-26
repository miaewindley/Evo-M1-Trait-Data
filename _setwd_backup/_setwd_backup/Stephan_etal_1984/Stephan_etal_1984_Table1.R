# Stephan_etal_1984_Table1.R
# Preparation step. Stephan, H., Baron, G., & Frahm, H. D. (1984). Comparative size of brains and brain components. (J. Hirnforsch.)
# Turn the journal-faithful snapshot into a lean, analysis-ready CSV (values from
# the curated comparison CSV Stephan_1984.csv; volumes in mm3). Output from the snapshot only.
suppressPackageStartupMessages({ library(readxl); library(readr); library(dplyr); library(stringr) })
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())
  setwd("/Users/crossmodal/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/_setwd_backup/_setwd_backup/Stephan_etal_1984")
snapshot_file <- "Stephan_etal_1984_Table1_snapshot.xlsx"; snapshot_sheet <- "Table1"; output_file <- "Stephan_etal_1984_Table1.csv"
header_rows <- 2L   # row1 caption + row2 header
pos <- c("code", "species_disp", "n_raw", "Corpus_geniculatum_laterale_mm3")
num <- function(x) parse_number(as.character(x), na = c("", "-", "NA", "n.a.", "__"))
raw <- read_excel(snapshot_file, sheet = snapshot_sheet, col_names = FALSE, col_types = "text")
dat <- raw %>% slice(-(seq_len(header_rows))); names(dat)[seq_along(pos)] <- pos
final.dataframe <- dat %>% filter(!is.na(Species_Stephan1984_disp := NULL) | TRUE) %>%   # keep species rows
  filter(!is.na(num(Corpus_geniculatum_laterale_mm3))) %>%
  transmute(code = str_squish(code), Species_Stephan1984 = str_squish(species_disp), n = as.integer(num(n_raw)),
            Corpus_geniculatum_laterale_mm3 = num(Corpus_geniculatum_laterale_mm3))
write.csv(final.dataframe, output_file, row.names = FALSE)
filecodes <- read_excel("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/__ReadMe.xlsx", sheet="Sheet1")
ie <- filecodes$"Item encoded"[match("Stephan_etal_1984_Table1", filecodes$"Item name")]
if (!is.na(ie) && nzchar(ie)) write.table(final.dataframe, paste0("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/__Public/comparative-data/", ie, ".tsv"), sep="\t", row.names=FALSE)
