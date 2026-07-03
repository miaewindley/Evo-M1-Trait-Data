## =============================================================================
## de Sousa et al. (2010) formatted Excel snapshot --> csv/tsv data outout
## Hominoid visual brain structure volumes and the position of the lunate sulcus
## DOI: 10.1016/j.jhevol.2009.11.011
## =============================================================================
##

## =============================================================================

## ---- setup -------------------------------------------------------------------
suppressPackageStartupMessages({ library(readxl); library(tidyverse) })
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
study <- basename(folder)

setwd(folder)
pdf_file      <- paste0(study, ".pdf")
snapshot_file <- paste0(item_name, "_snapshot.xlsx")

required_packages <- c("pdftools", "stringr", "dplyr", "tibble", "openxlsx")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages) > 0L) {
  stop(
    "Install these packages first: ", paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

# make this data usable:
# take out all the superscript letter-symbols and out of the cells, and code those information into new columns
# ensure numbers are numerical data

output_file <- paste0(item_name, ".csv")
write.csv(final.dataframe, output_file, row.names = FALSE)
## ---- also write the DOI/PMID-coded TSV to __Public/comparative-data/ (skipped if shared repo absent) ----
tsv_dir <- file.path(base, "__Public/comparative-data")
enc <- if (!is.na(base) && file.exists(file.path(base, "__ReadMe.xlsx"))) {
  filecodes <- readxl::read_excel(file.path(base, "__ReadMe.xlsx"), sheet = "Sheet1")
  filecodes$"Item encoded"[match(item_name, filecodes$"Item name")]
} else NA_character_
if (is.na(enc) || !nzchar(enc)) {
  warning("No 'Item encoded' for '", item_name, "' in __ReadMe.xlsx; TSV skipped.")
} else if (!dir.exists(path.expand(tsv_dir))) {
  warning("Shared folder not found: ", tsv_dir, "; TSV skipped.")
} else {
  write.table(final.dataframe, file = file.path(tsv_dir, paste0(enc, ".tsv")), sep = "\t", row.names = FALSE)
  message("Wrote ", file.path(tsv_dir, paste0(enc, ".tsv")))
}
