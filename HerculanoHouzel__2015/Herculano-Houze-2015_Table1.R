## =============================================================================
## Herculano-Houzel (2015) Table 1  -->  analysis-ready CSV
## Decreasing sleep requirement ... Proc Biol Sci 282(1816), 20151853.
## DOI: 10.1098/rspb.2015.1853   |   PMC: PMC4614783
## =============================================================================
##
## PROVENANCE -- why this table was captured from HTML, not the PDF
## -----------------------------------------------------------------------------
## Table 1 is printed in ROTATED LANDSCAPE across two pages and does not extract
## cleanly from the PDF (contrast Table 2 in this folder, which uses tabulapdf
## on the PDF). It was therefore captured from the open-access PMC HTML version
## and then cross-checked CELL-BY-CELL against the published PDF. All data values
## were confirmed to match the PDF; the per-cell reference citations [n] and the
## footnote markers (*, a, b, c) were taken from the published table.
##   Source (HTML): https://pmc.ncbi.nlm.nih.gov/articles/PMC4614783/
##
## SNAPSHOT RULE -- the one thing to get right
## -----------------------------------------------------------------------------
## The snapshot is the FROZEN, FAITHFUL copy of the table AS PUBLISHED. It keeps
## the reference citations [n], the footnote markers (*, a, b, c), the units,
## the scientific notation and the clade header rows. It is written BEFORE any
## cleaning, and every step below operates on it -- so the clean data is always
## traceable back to the source.
##   The committed *_snapshot.csv is AUTHORITATIVE. The scrape block only
##   regenerates it if it is missing, so a re-run never clobbers the verified
##   hardcopy. (This satisfies the pipeline rule: "save a reference hardcopy
##   file even if it can be accessed through URL.")
## =============================================================================


## 0. PATHS (no setwd) ---------------------------------------------------------
library(rstudioapi)

script_path   <- rstudioapi::getActiveDocumentContext()$path
paper_dir     <- dirname(script_path)
dataset_root  <- dirname(paper_dir)
table_name    <- tools::file_path_sans_ext(basename(script_path))

snapshot_csv  <- file.path(paper_dir, paste0(table_name, "_snapshot.csv"))
final_csv     <- file.path(paper_dir, paste0(table_name, ".csv"))


## 1. SOURCE  -->  SNAPSHOT (faithful capture, written before any cleaning) -----
library(rvest)
library(tidyverse)

if (!file.exists(snapshot_csv)) {
  page <- read_html("https://pmc.ncbi.nlm.nih.gov/articles/PMC4614783/")
  raw  <- (page |> html_elements("table") |> html_table(fill = TRUE))[[1]]

  # The scraped header row is split/garbled by html_table(); restore the column
  # labels exactly as printed in the published Table 1 so the snapshot can be
  # eyeballed against the paper.
  colnames(raw) <- c("species", "brain mass (g or cm3)", "daily sleep (h)",
                     "D/A (N mg−1 mm−2)", "NCX", "DNCX (N mg−1)",
                     "ACX (mm2)", "O/N", "T", "MCX (g or cm3)")

  write.csv(raw, snapshot_csv, row.names = FALSE)   # <== SNAPSHOT FROZEN HERE
}


## 2. DATA READABLE (snapshot --> analysis-ready) ------------------------------
## Read the frozen snapshot back; all cleaning happens here, never above.
df <- read.csv(snapshot_csv, check.names = FALSE,
               stringsAsFactors = FALSE, fileEncoding = "UTF-8")

## 2.1 Remove reference citations in square brackets, e.g. "15.750 [19]" -------
df[] <- lapply(df, function(x) gsub("\\[.*?\\]", "", x))

## 2.2 Convert "n.a." to NA ----------------------------------------------------
df[] <- lapply(df, function(x) ifelse(trimws(x) == "n.a.", NA, x))

## 2.3 Remove footnote asterisks, e.g. "59 280*" -------------------------------
df[] <- lapply(df, function(x) gsub("\\*", "", x))

## 2.4 Remove trailing footnote letters on numbers, e.g. "218a", "...106b" -----
df[ , -1] <- lapply(df[ , -1], function(x) gsub("([0-9])([A-Za-z])$", "\\1", x))

## 2.5 Remove thousands spaces, e.g. "47 960" -> "47960" -----------------------
df[ , -1] <- lapply(df[ , -1], function(x) gsub(" ", "", x))

## 2.6 Remove any stray letters left in the numeric columns --------------------
df[ , -1] <- lapply(df[ , -1], function(x) gsub("[A-Za-z]", "", x))

## 2.7 Scientific notation in NCX: "X × 10^n" / "X × 10n" -> "Xen" ----
convert_index_form <- function(x) {
  x <- gsub("×10\\^", "e", x)   # handles the "x 10^" form
  x <- gsub("×10",    "e", x)   # handles the "x 10"  form
  x
}
df[["NCX"]] <- convert_index_form(df[["NCX"]])

## 2.8 Types: species stays character, every other column becomes numeric ------
df[[1]]   <- as.character(df[[1]])
df[ , -1] <- lapply(df[ , -1], as.numeric)

## 2.9 Turn the clade header rows into a "category" column, then drop them ------
categories <- c("Primates", "Eulipotyphla", "Glires",
                "Afrotheria", "Artiodactyla", "Scandentia")

df <- df |>
  mutate(category = if_else(species %in% categories, species, NA_character_)) |>
  fill(category, .direction = "down") |>
  filter(!species %in% categories) |>
  relocate(category, .after = species)


## 3. SAVE FINAL ---------------------------------------------------------------
write.csv(df, final_csv, row.names = FALSE)

## 4. ONLINE DATABASE (optional, when ready) -----------------------------------
## Save a TSV named with the DOI-encoded item name to the public mirror:
##   item_encoded <- "10.1098%2Frspb.2015.1853_Table1"
##   write.table(df, file.path(dataset_root, "__Public", "comparative-data",
##               paste0(item_encoded, ".tsv")), sep = "\t", row.names = FALSE)
