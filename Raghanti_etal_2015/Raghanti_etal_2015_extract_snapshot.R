## Raghanti MA, Spurlock LB, Treichler FR, Weigel SE, Stimmelmayr R, Butti C,
## Thewissen JGM, Hof PR (2015). An analysis of von Economo neurons in the
## cerebral cortex of cetaceans, artiodactyls, and perissodactyls.
## Brain Struct Funct 220(4):2303-2314. doi:10.1007/s00429-014-0792-y
##
## Source -> frozen snapshot. Scrapes the publisher's HTML table page (snapshot
## HOWTO, method 2) and writes the frozen copy BEFORE any cleaning:
##   Raghanti_etal_2015_Table1_snapshot.xlsx   (sheet "Table1")
##
## .xlsx, not .csv: the printed header is two tiers deep - each of the four
## cortical regions spans a "% VEN" and a "% Fork cells" column, and "Species"
## spans both rows. CSV flattens that. The merges are reproduced so the frozen
## copy reads like the page.
##
## No table values are typed into this script. The printed literals are the four
## region names and the two measure names, used as anchors to verify the scrape.
##
## Refuses to overwrite a differing frozen copy: writes *_REBUILD.xlsx and stops.

library(rvest)
library(xml2)
library(openxlsx)
library(readxl)

options(stringsAsFactors = FALSE)

.sp <- local({
  a <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  if (length(a)) return(normalizePath(sub("^--file=", "", a[1])))
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    p <- rstudioapi::getSourceEditorContext()$path
    if (!nzchar(p)) p <- rstudioapi::getActiveDocumentContext()$path
    if (nzchar(p)) return(normalizePath(p))
  }
  stop("Run with Rscript file.R, or open in RStudio and click Source (save first).", call. = FALSE)
})
folder <- dirname(.sp)
setwd(folder)

src_url    <- "https://link.springer.com/article/10.1007/s00429-014-0792-y/tables/1"
local_html <- "Raghanti_etal_2015_Table1.html"   # optional offline copy of the table page
t1_xlsx    <- "Raghanti_etal_2015_Table1_snapshot.xlsx"

regions  <- c("Frontal pole", "ACC", "Anterior insula", "Occipital pole")
measures <- c("% VEN", "% Fork cells")

## ---- 1. get the page ----
doc <- if (file.exists(local_html)) {
  message("reading local copy: ", local_html)
  read_html(local_html, encoding = "UTF-8")
} else {
  message("fetching: ", src_url)
  read_html(src_url)
}

tbl <- html_element(doc, "table")
if (inherits(tbl, "xml_missing")) stop("no table found on the page")
rows <- html_elements(tbl, "tr")

cell_text <- function(c) {
  s <- gsub(" ", " ", html_text2(c))
  trimws(gsub("[[:space:]]+", " ", s))
}

## ---- 2. header: two tiers, read from the spans rather than assumed ----
h1 <- html_elements(rows[[1]], "td, th")
h2 <- html_elements(rows[[2]], "td, th")
h1_txt <- vapply(h1, cell_text, character(1))
h1_cs  <- as.integer(ifelse(is.na(html_attr(h1, "colspan")), 1, html_attr(h1, "colspan")))
h1_rs  <- as.integer(ifelse(is.na(html_attr(h1, "rowspan")), 1, html_attr(h1, "rowspan")))

stopifnot(h1_txt[1] == "Species", h1_rs[1] == 2L)      # Species spans both header rows
stopifnot(identical(h1_txt[-1], regions))               # four regions, in printed order
stopifnot(all(h1_cs[-1] == 2L))                         # each spanning two columns
stopifnot(identical(vapply(h2, cell_text, character(1)),
                    rep(measures, times = 4)))          # % VEN, % Fork cells, x4

## ---- 3. body ----
body <- lapply(rows[-(1:2)], function(r) vapply(html_elements(r, "td, th"), cell_text, character(1)))
stopifnot(all(lengths(body) == 9L))
body <- do.call(rbind, body)
stopifnot(nrow(body) == 8L)                             # eight species, one individual each

## ---- 4. write the frozen copy, merges as printed ----
wb <- createWorkbook()
addWorksheet(wb, "Table1")
writeData(wb, "Table1", h1_txt[1], startRow = 1, startCol = 1, colNames = FALSE)
for (i in seq_along(regions)) {
  writeData(wb, "Table1", regions[i], startRow = 1, startCol = 2 + 2 * (i - 1), colNames = FALSE)
  writeData(wb, "Table1", t(measures), startRow = 2, startCol = 2 + 2 * (i - 1), colNames = FALSE)
  mergeCells(wb, "Table1", cols = (2 + 2 * (i - 1)):(3 + 2 * (i - 1)), rows = 1)
}
mergeCells(wb, "Table1", cols = 1, rows = 1:2)
writeData(wb, "Table1", as.data.frame(body), startRow = 3, colNames = FALSE)
addStyle(wb, "Table1", createStyle(textDecoration = "bold"),
         rows = 1:2, cols = 1:9, gridExpand = TRUE)
setColWidths(wb, "Table1", cols = 1:9, widths = c(16, rep(13, 8)))

if (file.exists(t1_xlsx)) {
  old <- as.matrix(read_excel(t1_xlsx, sheet = "Table1", col_types = "text",
                              col_names = FALSE, skip = 2, .name_repair = "minimal"))
  old[is.na(old)] <- ""
  if (!identical(unname(old), unname(body))) {
    saveWorkbook(wb, sub("\\.xlsx$", "_REBUILD.xlsx", t1_xlsx), overwrite = TRUE)
    stop("Frozen Table 1 differs from the page. Wrote *_REBUILD.xlsx; compare before replacing.")
  }
  message("Table 1: frozen copy matches the page.")
} else {
  saveWorkbook(wb, t1_xlsx, overwrite = FALSE)
  message("Table 1: frozen copy written.")
}
