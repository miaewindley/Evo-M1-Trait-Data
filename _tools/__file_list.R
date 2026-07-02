# __file_list.R
# -----------------------------------------------------------------------------
# 1. Writes a "FileList" sheet to __ReadMe.xlsx listing the .tsv files in
#    __Public/comparative-data (one file name per row, no header).
# 2. Reports (to the R console only) the .tsv files in that folder whose name
#    is NOT catalogued in Sheet1 column L ("Item encoded"). These are orphan
#    data files (e.g. a .tsv that was renamed and no longer matches its encoded
#    entry in the ReadMe). No FileStrays sheet is written; any leftover
#    FileStrays sheet from a previous run is removed.
#
# Re-running is safe: the FileList sheet is rebuilt each time; all other sheets
# (except a stale FileStrays) are preserved.
# -----------------------------------------------------------------------------

library(openxlsx)

# ---- Paths ------------------------------------------------------------------
## project root = nearest ancestor containing __ReadMe.xlsx (works from _tools/ or root,
## and on any clone, via Rscript / source() / RStudio)
.script_path <- local({
  argv <- commandArgs(FALSE)
  f <- sub("^--file=", "", argv[grep("^--file=", argv)])
  if (length(f) == 1L && nzchar(f)) return(normalizePath(f))
  sf <- tryCatch(normalizePath(sys.frames()[[1]]$ofile), error = function(e) NULL)
  if (!is.null(sf) && nzchar(sf)) return(sf)
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    p <- rstudioapi::getActiveDocumentContext()$path
    if (nzchar(p)) return(normalizePath(p))
  }
  normalizePath(getwd())
})
root_dir <- local({
  d <- if (file.exists(.script_path)) dirname(.script_path) else normalizePath(getwd())
  while (dirname(d) != d && !file.exists(file.path(d, "__ReadMe.xlsx"))) d <- dirname(d)
  if (file.exists(file.path(d, "__ReadMe.xlsx"))) d
  else if (file.exists(.script_path)) dirname(.script_path) else normalizePath(getwd())
})
readme_xlsx <- file.path(root_dir, "__ReadMe.xlsx")
file_dir    <- file.path(root_dir, "__Public", "comparative-data")

# ---- .tsv files in the folder -----------------------------------------------
tsv_files <- list.files(file_dir, pattern = "\\.tsv$", ignore.case = TRUE)

# ---- Catalogued names from Sheet1 column L ("Item encoded") -----------------
# Read Sheet1 keeping the exact column positions (skipEmptyCols = FALSE) so that
# the 12th column is always column L.
sheet1 <- read.xlsx(
  readme_xlsx,
  sheet         = "Sheet1",
  colNames      = TRUE,
  skipEmptyCols = FALSE,
  skipEmptyRows = FALSE
)

col_L_index <- 12  # column L
col_L_name  <- names(sheet1)[col_L_index]
if (!grepl("Item.?encoded", col_L_name, ignore.case = TRUE)) {
  warning(sprintf(
    "Column L is '%s', not the expected 'Item encoded'. Check column alignment.",
    col_L_name
  ))
}

# NOTE: column L is an Excel formula; read.xlsx returns the cached values Excel
# stored on last save. If the cache is ever empty this guard stops the run so we
# don't wrongly flag every .tsv as a stray.
encoded <- trimws(as.character(sheet1[[col_L_index]]))
encoded <- encoded[!is.na(encoded) & nzchar(encoded)]
if (length(encoded) == 0) {
  stop("No values read from Sheet1 column L ('Item encoded'). ",
       "Open __ReadMe.xlsx in Excel and save it so the formula values are cached, then re-run.")
}

# ---- Orphan .tsv check (console only) ---------------------------------------
# A .tsv is a match if its name without the extension is in column L.
# Also allow a full-name match, in case an L entry includes the extension.
tsv_stems <- tools::file_path_sans_ext(tsv_files)
is_match  <- tsv_stems %in% encoded | tsv_files %in% encoded
strays    <- tsv_files[!is_match]

# ---- Write FileList (.tsv only, no header); drop any stale FileStrays --------
wb <- loadWorkbook(readme_xlsx)
if ("FileList"   %in% names(wb)) removeWorksheet(wb, "FileList")
if ("FileStrays" %in% names(wb)) removeWorksheet(wb, "FileStrays")

addWorksheet(wb, "FileList")
writeData(
  wb,
  sheet    = "FileList",
  x        = data.frame(tsv_files, stringsAsFactors = FALSE),
  colNames = FALSE
)

saveWorkbook(wb, readme_xlsx, overwrite = TRUE)

# ---- Console summary --------------------------------------------------------
cat(sprintf("FileList: %d .tsv files written to __ReadMe.xlsx (no header)\n",
            length(tsv_files)))
cat(sprintf("Orphan .tsv file(s) not found in Sheet1 column L: %d\n", length(strays)))
if (length(strays) > 0) {
  cat(paste0("  - ", strays, collapse = "\n"), "\n")
} else {
  cat("  (none)\n")
}
