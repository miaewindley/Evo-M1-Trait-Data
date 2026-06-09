#!/usr/bin/env Rscript

# Extract Table 2 from Bauernfeind et al. 2013, printed page 271
# and write a text-readable Excel snapshot.
#
# Input:  bauernfeind_etal_2013.pdf in the current working directory
# Output: Bauernfeind_etal_2013_Table2_snapshot.xlsx
#
# Notes:
# - The article's printed page 271 is PDF page 9.
# - Coordinates are PDF points in Tabula/tabulizer's top-left origin:
#   area = c(top, left, bottom, right).
# - The crop targets the bottom-left Table 2 block only.

pdf_file <- "bauernfeind_etal_2013.pdf"
out_file <- "Bauernfeind_etal_2013_Table2_snapshot.xlsx"
pdf_page <- 9L

# Table 2 crop on PDF page 9 / printed page 271.
# The table caption begins at y ~520; the tabular body begins at y ~548.
caption_area <- c(518, 40, 545, 300)
table_area   <- c(548, 40, 741, 300)

# Column separators estimated from the Table 2 x positions.
# These split into: Species, Individual, Granular, Dysgranular,
# Agranular, FI, Total insula volume.
col_separators <- c(89, 136, 171, 205, 237, 259)

required <- c("openxlsx")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing) > 0) {
  stop("Install missing package(s): ", paste(missing, collapse = ", "), call. = FALSE)
}
if (!file.exists(pdf_file)) {
  stop("PDF not found: ", normalizePath(pdf_file, mustWork = FALSE), call. = FALSE)
}

squish_matrix <- function(x) {
  x <- as.matrix(x)
  x[is.na(x)] <- ""
  x <- apply(x, c(1, 2), function(z) {
    z <- gsub("\\r|\\n", " ", z)
    z <- gsub("[[:space:]]+", " ", z)
    trimws(z)
  })
  x <- x[rowSums(x != "") > 0, , drop = FALSE]
  x <- x[, colSums(x != "") > 0, drop = FALSE]
  x
}

extract_with_tabula <- function() {
  if (!requireNamespace("tabulizer", quietly = TRUE)) return(NULL)

  attempts <- list(
    list(method = "stream",  area = list(table_area), columns = list(col_separators)),
    list(method = "lattice", area = list(table_area), columns = NULL),
    list(method = "stream",  area = list(c(518, 40, 741, 300)), columns = list(col_separators))
  )

  for (a in attempts) {
    res <- tryCatch(
      tabulizer::extract_tables(
        file = pdf_file,
        pages = pdf_page,
        guess = FALSE,
        area = a$area,
        columns = a$columns,
        method = a$method,
        output = "matrix"
      ),
      error = function(e) NULL
    )
    if (length(res) >= 1) {
      mat <- squish_matrix(res[[1]])
      if (nrow(mat) >= 8 && ncol(mat) >= 4) return(mat)
    }
  }
  NULL
}

extract_with_pdftools <- function() {
  if (!requireNamespace("pdftools", quietly = TRUE)) {
    stop(
      "Could not extract with tabulizer, and pdftools is not installed.\n",
      "Install tabulizer plus Java/rJava, or install pdftools for the coordinate fallback.",
      call. = FALSE
    )
  }

  dat <- pdftools::pdf_data(pdf_file)[[pdf_page]]
  dat <- dat[dat$x >= table_area[2] & dat$x <= table_area[4] &
               dat$y >= table_area[1] & dat$y <= table_area[3], ]
  if (nrow(dat) == 0) stop("No text found in the specified Table 2 crop.", call. = FALSE)

  dat <- dat[order(dat$y, dat$x), ]

  # Cluster text lines by y coordinate. A 3-point tolerance handles superscript-like
  # offsets while keeping adjacent table rows separated.
  y_sorted <- sort(unique(dat$y))
  row_map <- integer(length(y_sorted))
  row_map[1] <- 1L
  for (i in seq_along(y_sorted)[-1]) {
    row_map[i] <- row_map[i - 1] + as.integer((y_sorted[i] - y_sorted[i - 1]) > 3)
  }
  names(row_map) <- as.character(y_sorted)
  dat$row_id <- unname(row_map[as.character(dat$y)])

  # Assign words to the seven visual table columns.
  dat$col_id <- findInterval(dat$x, vec = c(-Inf, col_separators, Inf), rightmost.closed = TRUE)

  nr <- max(dat$row_id)
  nc <- 7L
  mat <- matrix("", nrow = nr, ncol = nc)
  for (r in seq_len(nr)) {
    for (c in seq_len(nc)) {
      words <- dat$text[dat$row_id == r & dat$col_id == c]
      if (length(words) > 0) mat[r, c] <- paste(words, collapse = " ")
    }
  }
  colnames(mat) <- c("Species", "Individual", "Granular", "Dysgranular", "Agranular", "FI", "Total insula volume")
  squish_matrix(mat)
}

message("Extracting Table 2 from ", pdf_file, " page ", pdf_page, " ...")
tbl <- extract_with_tabula()
extractor <- "tabulizer"
if (is.null(tbl)) {
  message("tabulizer extraction unavailable or low quality; falling back to pdftools coordinates.")
  tbl <- extract_with_pdftools()
  extractor <- "pdftools"
}

# Build a text-readable Excel snapshot. Values are kept as text to preserve the
# visual layout rather than forcing a tidy analytical table.
wb <- openxlsx::createWorkbook()
openxlsx::addWorksheet(wb, "Table2_snapshot", gridLines = FALSE)
openxlsx::addWorksheet(wb, "Extraction_notes", gridLines = FALSE)

caption <- c(
  "Table 2",
  "Stereologic estimates of shrinkage-corrected volumes (cm^3) for right insula and its subdivisions in each human and great ape sampled."
)

openxlsx::writeData(wb, "Table2_snapshot", caption[1], startRow = 1, startCol = 1)
openxlsx::writeData(wb, "Table2_snapshot", caption[2], startRow = 2, startCol = 1)
openxlsx::writeData(wb, "Table2_snapshot", as.data.frame(tbl, stringsAsFactors = FALSE),
                    startRow = 4, startCol = 1, colNames = FALSE)

# Formatting for readability.
title_style <- openxlsx::createStyle(textDecoration = "bold", fontSize = 12)
caption_style <- openxlsx::createStyle(wrapText = TRUE, valign = "top")
header_style <- openxlsx::createStyle(textDecoration = "bold", border = "bottom", valign = "top")
body_style <- openxlsx::createStyle(wrapText = TRUE, valign = "top")

openxlsx::addStyle(wb, "Table2_snapshot", title_style, rows = 1, cols = 1, gridExpand = TRUE)
openxlsx::addStyle(wb, "Table2_snapshot", caption_style, rows = 2, cols = 1:7, gridExpand = TRUE)
openxlsx::addStyle(wb, "Table2_snapshot", body_style, rows = 4:(nrow(tbl) + 3), cols = 1:ncol(tbl), gridExpand = TRUE)
openxlsx::addStyle(wb, "Table2_snapshot", header_style, rows = 4:min(6, nrow(tbl) + 3), cols = 1:ncol(tbl), gridExpand = TRUE, stack = TRUE)
openxlsx::mergeCells(wb, "Table2_snapshot", cols = 1:7, rows = 2)
openxlsx::setColWidths(wb, "Table2_snapshot", cols = 1:7, widths = c(18, 16, 11, 14, 12, 8, 14))
openxlsx::setRowHeights(wb, "Table2_snapshot", rows = 1:(nrow(tbl) + 3), heights = "auto")
openxlsx::freezePane(wb, "Table2_snapshot", firstActiveRow = 4)

notes <- data.frame(
  field = c("source_pdf", "printed_page", "pdf_page", "extractor", "table_area_top_left_bottom_right_pts", "column_separators_pts", "output"),
  value = c(pdf_file, "271", as.character(pdf_page), extractor,
            paste(table_area, collapse = ", "), paste(col_separators, collapse = ", "), out_file),
  stringsAsFactors = FALSE
)
openxlsx::writeData(wb, "Extraction_notes", notes, startRow = 1, startCol = 1, colNames = TRUE)
openxlsx::setColWidths(wb, "Extraction_notes", cols = 1:2, widths = c(36, 80))

openxlsx::saveWorkbook(wb, out_file, overwrite = TRUE)
message("Wrote: ", normalizePath(out_file, mustWork = FALSE))
