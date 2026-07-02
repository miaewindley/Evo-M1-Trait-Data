## Mota B, Dos Santos SE, Ventura-Antunes L, et al. (2019), PNAS 116(30):15253-15261
## "White matter volume and white/gray matter ratio in mammalian species as a
##  consequence of the universal scaling of cortical folding."
## Supplementary Table S1 -> clean. Golden rule: the snapshot is frozen/faithful;
## ALL cleaning (drop group-header rows, parse numbers) happens here.
## Columns (as printed): VT/VG/VW = total/gray/white cortical volume (mm3);
##   AT = total cortical area, AE = exposed cortical area (mm2); T = thickness (mm);
##   N = number of cortical neurons.

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
folder <- paper_dir <- dirname(.sp)                                   # this paper's folder
item_name <- table_name <- tools::file_path_sans_ext(basename(.sp))  # = file name (matches __ReadMe.xlsx)
base <- dataset_root <- local({                                      # repo root; NA if run as a lone folder
  d <- folder
  while (dirname(d) != d && !file.exists(file.path(d, "__ReadMe.xlsx"))) d <- dirname(d)
  if (file.exists(file.path(d, "__ReadMe.xlsx"))) d else NA_character_
})
setwd(folder)
options(scipen = 999)

suppressPackageStartupMessages({
  library(readxl); library(dplyr); library(stringr); library(readr)
})

snapshot_xlsx  <- file.path(folder, paste0(item_name, ".xlsx"))
final_csv      <- file.path(folder, paste0(item_name, ".csv"))
readme_xlsx    <- file.path(base, "__ReadMe.xlsx")
public_tsv_dir <- file.path(base, "__Public", "comparative-data")

## ---- read the faithful table: row 1 = title, row 2 = header, rows 3+ = data ----
raw <- read_excel(snapshot_xlsx, sheet = "Sheet1", col_names = FALSE, col_types = "text")
dat <- raw[-c(1, 2), , drop = FALSE]
# published header order is fixed: Species, VT, VG, VW (mm3), AT (mm2), T (mm), AE (mm2), N
names(dat) <- c("Species", "VT_mm3", "VG_mm3", "VW_mm3", "AT_mm2", "T_mm", "AE_mm2", "N")

num  <- function(x) parse_number(x, na = c("", "NA", "-", "n.a."))
meas <- c("VT_mm3", "VG_mm3", "VW_mm3", "AT_mm2", "T_mm", "AE_mm2", "N")

# A row with a label but no measurements is a taxonomic-order header (Rodentia,
# Primata, ...) or the trailing footnote. Forward-fill the order onto species rows.
has_meas <- rowSums(!is.na(dat[meas])) > 0
is_group <- !is.na(dat$Species) & nzchar(str_squish(dat$Species)) & !has_meas

taxon_group <- character(nrow(dat)); grp <- NA_character_
for (i in seq_len(nrow(dat))) {
  if (isTRUE(is_group[i])) grp <- str_squish(dat$Species[i])
  taxon_group[i] <- grp
}
dat$taxon_group <- taxon_group

clean <- dat[has_meas, , drop = FALSE] %>%              # keep only species rows
  transmute(
    taxon_group,
    Species = str_squish(Species),
    VT_mm3 = num(VT_mm3), VG_mm3 = num(VG_mm3), VW_mm3 = num(VW_mm3),
    AT_mm2 = num(AT_mm2), T_mm = num(T_mm), AE_mm2 = num(AE_mm2),
    N = num(N)
  )

## ---- SAVE: local CSV + guarded DOI-coded TSV --------------------------------
write.csv(clean, final_csv, row.names = FALSE)
message("Wrote ", final_csv, "  (", nrow(clean), " species rows)")

enc <- if (!is.na(base) && file.exists(readme_xlsx)) {
  fc <- read_excel(readme_xlsx, sheet = "Sheet1")
  fc$`Item encoded`[match(item_name, fc$`Item name`)]
} else NA_character_

if (length(enc) != 1L || is.na(enc) || !nzchar(enc)) {
  warning("No 'Item encoded' (DOI) for '", item_name, "' in __ReadMe.xlsx; TSV skipped.")
} else {
  dir.create(public_tsv_dir, recursive = TRUE, showWarnings = FALSE)
  tsv_path <- file.path(public_tsv_dir, paste0(enc, ".tsv"))
  write.table(clean, tsv_path, sep = "\t", row.names = FALSE)
  message("Wrote ", tsv_path)
}
