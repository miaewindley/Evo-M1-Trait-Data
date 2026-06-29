# Stephan_etal_1981_Table1.R
#
# Preparation step. Turn the snapshot of Stephan, Frahm & Baron (1981) "New and
# revised data on volumes of brain structures in insectivores and primates" into
# a lean, analysis-ready CSV. Output comes from the snapshot only.
#
# Snapshot layout: row 1 caption, row 2 header, rows 3+ the 76 species in Stephan
# code (taxonomic) order. Columns: code, species, then the 44 structure volumes
# interleaved with the 6 "n (range)" sample-size columns, in Stephan's code order.
# Body weight in g, brain weight in mg, all other structures in mm3.
#
# This script cleans the journal-style headers to R-friendly names and types the
# values. Current accepted species names + taxonomy are applied downstream via
# ../_keys/Stephan/.
#
# Input  : Stephan_etal_1981_Table1_snapshot.xlsx        sheet: Table1
# Outputs: Stephan_etal_1981_Table1.csv                  one row per species (76)
#          <DOI/PMID>.tsv in __Public/comparative-data/   named from __ReadMe.xlsx
#
# Laterality note for Stephan 1981 vestibular structures (codes 35-39):
# Baron et al. 1988 later states that the Stephan et al. 1981 vestibular
# nucleus volumes were measured from one side only, while the 1988 data were
# from both sides. To prevent accidental comparison with bilateral values, the
# five vestibular output columns are suffixed _unilateral. Values are not
# doubled here; any bilateral estimate should be derived downstream and flagged.

suppressPackageStartupMessages({ library(readxl); library(readr); library(dplyr); library(stringr) })
## ---- paths: self-contained (Rscript or RStudio; full repo or lone folder) ----
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
snapshot_file  <- "Stephan_etal_1981_Table1_snapshot.xlsx"
snapshot_sheet <- "Table1"
output_file    <- "Stephan_etal_1981_Table1.csv"
header_rows    <- 1L   # row 1 caption; row 2 header; data from row 3

# These columns correspond to Stephan 1981 codes 35-39. The 1981 paper itself
# lists them as vestibular-complex/component volumes, but Baron et al. 1988
# clarifies that the earlier values were from one side only. We use
# "unilateral" rather than "hemisphere" because these are brainstem nuclei.
unilateral_vestibular_renames <- c(
  Complexus_vestibularis = "Complexus_vestibularis_unilateral",
  Nucleus_vestibularis_superior = "Nucleus_vestibularis_superior_unilateral",
  Nucleus_vestibularis_lateralis = "Nucleus_vestibularis_lateralis_unilateral",
  Nucleus_vestibularis_medialis = "Nucleus_vestibularis_medialis_unilateral",
  Nucleus_vestibularis_descendens = "Nucleus_vestibularis_descendens_unilateral"
)

mark_unilateral_vestibular <- function(nms) {
  hit <- nms %in% names(unilateral_vestibular_renames)
  nms[hit] <- unname(unilateral_vestibular_renames[nms[hit]])
  nms
}

num <- function(x) parse_number(as.character(x), na = c("", "-", "NA", "n.a.", "__"))
clean <- function(h) {
  ifelse(str_detect(h, "^n \\("),
         paste0("n_", str_replace_all(str_extract(h, "(?<=\\()[^)]+"), "\\s*to\\s*|\\s+", "_")),
         str_replace_all(str_squish(str_remove(h, "\\s*\\(\\d+\\)$")), " ", "_"))
}

raw <- read_excel(snapshot_file, sheet = snapshot_sheet, col_names = FALSE, col_types = "text")
header <- clean(as.character(unlist(raw[header_rows + 1, ], use.names = FALSE)))
dat <- raw[-(seq_len(header_rows + 1)), , drop = FALSE]
names(dat) <- mark_unilateral_vestibular(header)
dat <- dat[!is.na(dat$species) & str_squish(dat$species) != "", , drop = FALSE]
dat <- dplyr::rename(dat, Species = species)

# type every column except the two identifiers
id <- c("code", "Species")
final.dataframe <- dat %>%
  mutate(across(-all_of(id), num)) %>%
  mutate(code = str_squish(code), Species = str_squish(Species))

options(scipen = 999)

## ---- SAVE: local CSV + DOI/PMID-named TSV ----
write.csv(final.dataframe, file = paste0(item_name, ".csv"), row.names = FALSE)
message("Wrote ", item_name, ".csv  (", nrow(final.dataframe), " rows x ", ncol(final.dataframe), " cols)")

tsv_dir <- file.path(base, "__Public/comparative-data")
item_encoded <- if (!is.na(base) && file.exists(file.path(base, "__ReadMe.xlsx"))) {
  filecodes <- readxl::read_excel(file.path(base, "__ReadMe.xlsx"), sheet = "Sheet1")
  filecodes$"Item encoded"[match(item_name, filecodes$"Item name")]
} else NA_character_
if (is.na(item_encoded) || !nzchar(item_encoded)) {
  warning("No 'Item encoded' (DOI) for '", item_name, "' in __ReadMe.xlsx; TSV skipped.")
} else if (!dir.exists(path.expand(tsv_dir))) {
  warning("Shared folder not found: ", tsv_dir, "; TSV skipped.")
} else {
  write.table(final.dataframe, file = file.path(tsv_dir, paste0(item_encoded, ".tsv")), sep = "	", row.names = FALSE)
  message("Wrote ", file.path(tsv_dir, paste0(item_encoded, ".tsv")))
}
