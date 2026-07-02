# Stephan_etal_1988_Table1.R
#
# Stephan, H., Baron, G., & Frahm, H. D. (1988). Comparative size of brains and brain
# components. In H. D. Steklis & J. Erwin (Eds.), Comparative Primate Biology, Vol. 4:
# Neurosciences (pp. 1-38). New York: Alan R. Liss.  (__ReadMe item: Stephan_etal_1988 /
# Item number "TABLE 1"; identifier ISBN:0845140000 in __ReadMe.xlsx.)
#
# Table 1 = Body Weights (BoW, g), Brain Weights (BrW, mg) and Encephalization Indexes (EI)
# of Tenrecinae, Scandentia and the 45 primate species whose brain structures were measured,
# with ecoethological codes for the primates (activity / diet / locomotion / references).
# Output comes from the snapshot only.
#
# Snapshot layout (matches the printed Table 1): one leading "species" column carrying the
# grade headers as rows (Tenrecinae, Scandentia, Prosimians, Simians) and the species
# ("<code> <binomial>"), followed by BoW, BrW, EI and the four ecoethological columns; two
# footnote rows at the foot. Header: row1 caption, row2 tier-1 (BoW|BrW|EI|Ecoethological),
# row3 tier-2 ((g)|(mg)|(1)|(2)|(3)|(4)); data from row 4. Numbers are printed with thousands
# commas (e.g. 1,330,000) -- parse_number() strips them.
#
# Input  : Stephan_etal_1988_Table1_snapshot.xlsx       sheet: Table1
# Outputs: Stephan_etal_1988_Table1.csv                 one row per species (52)
#          <ISBN>_TABLE1.tsv in __Public/comparative-data/  (named from __ReadMe.xlsx)

suppressPackageStartupMessages({
  library(readxl); library(readr); library(dplyr); library(stringr)
})
## ---- paths: self-contained (Rscript or RStudio; full repo or lone folder) ----
## NOTE: the previous `if (rstudioapi::isAvailable()) setwd(...)` guard silently did nothing
## when run non-interactively via Rscript (as in run_all_scripts_v2.R), leaving the working
## directory at the repo root and breaking every relative path below.
.sp <- local({
  a <- grep("^--file=", commandArgs(FALSE), value = TRUE)             # Rscript file.R
  if (length(a)) return(normalizePath(sub("^--file=", "", a[1])))
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    p <- rstudioapi::getSourceEditorContext()$path                    # RStudio: Source
    if (!nzchar(p)) p <- rstudioapi::getActiveDocumentContext()$path  # RStudio: Run
    if (nzchar(p)) return(normalizePath(p))
  }
  stop("Run with Rscript file.R, or open in RStudio and click Source (save first).", call. = FALSE)
})
folder    <- dirname(.sp)                                # this paper's folder
item_name <- tools::file_path_sans_ext(basename(.sp))    # = file name, matches __ReadMe.xlsx
base      <- local({                                     # repo root; NA if run as a lone folder
  d <- folder
  while (dirname(d) != d && !file.exists(file.path(d, "__ReadMe.xlsx"))) d <- dirname(d)
  if (file.exists(file.path(d, "__ReadMe.xlsx"))) d else NA_character_
})
setwd(folder)

snapshot_file  <- "Stephan_etal_1988_Table1_snapshot.xlsx"
snapshot_sheet <- "Table1"
output_file    <- "Stephan_etal_1988_Table1.csv"
header_rows    <- 3L

pos <- c("species_disp","BoW","BrW","EI","activity","diet","locomotion","refs")
num <- function(x) parse_number(as.character(x), na = c("", "-", "NA", "n.a.", "__"))

raw <- read_excel(snapshot_file, sheet = snapshot_sheet, col_names = FALSE, col_types = "text")
dat <- raw %>% slice(-(seq_len(header_rows)))
names(dat)[seq_along(pos)] <- pos

final.dataframe <- dat %>%
  filter(!is.na(species_disp), !is.na(num(BoW))) %>%   # species rows = numeric BoW (drops grade-header & footnote rows)
  transmute(
    Stephan_code        = str_extract(species_disp, "^\\d{4}"),
    Species_Stephan1988 = str_squish(str_remove(species_disp, "^\\d{4}\\s*")),
    BoW_g               = num(BoW),
    BrW_mg              = num(BrW),
    EI                  = num(EI),
    activity            = na_if(str_squish(replace_na(activity, "")), ""),
    diet_category       = na_if(str_squish(replace_na(diet, "")), ""),
    locomotion          = na_if(str_squish(replace_na(locomotion, "")), ""),
    ecoethology_refs    = na_if(str_replace_all(replace_na(refs, ""), "\\s+", ""), ""),
    source              = "Stephan_etal_1988"
  )

options(scipen = 999)

## ---- SAVE: local CSV + identifier-named TSV (named from __ReadMe.xlsx 'Item encoded') ----
## item_name already resolved above (self-contained path block) -- matches this file's name.
write.csv(final.dataframe, file = paste0(item_name, ".csv"), row.names = FALSE)
message("Wrote ", item_name, ".csv  (", nrow(final.dataframe), " rows)")

readme_file <- "~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/__ReadMe.xlsx"
tsv_dir     <- "~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/__Public/comparative-data/"
filecodes    <- read_excel(readme_file, sheet = "Sheet1")
# __ReadMe 'Item name' is a formula (strips spaces/underscores from the Item number, e.g.
# "TABLE 1" -> "Stephan_etal_1988_TABLE1"); match on a case/separator-insensitive key.
norm_key     <- function(x) tolower(gsub("[ _]", "", as.character(x)))
item_encoded <- filecodes$"Item encoded"[match(norm_key(item_name), norm_key(filecodes$"Item name"))]
if (is.na(item_encoded) || !nzchar(item_encoded)) {
  warning("No 'Item encoded' for '", item_name, "' in __ReadMe.xlsx; TSV skipped.")
} else if (!dir.exists(path.expand(tsv_dir))) {
  warning("Shared folder not found: ", tsv_dir, "; TSV skipped.")
} else {
  write.table(final.dataframe, file = paste0(tsv_dir, item_encoded, ".tsv"), sep = "\t", row.names = FALSE)
  message("Wrote ", tsv_dir, item_encoded, ".tsv")
}
