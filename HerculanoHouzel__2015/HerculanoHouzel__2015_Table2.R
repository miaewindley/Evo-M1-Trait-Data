## 0. PATHS (NO setwd) -------------------------------------------------------

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
item_name <- tools::file_path_sans_ext(basename(.sp))  # = file name (matches __ReadMe.xlsx)
base <- dataset_root <- local({                                      # repo root; NA if run as a lone folder
  d <- folder
  while (dirname(d) != d && !file.exists(file.path(d, "__ReadMe.xlsx"))) d <- dirname(d)
  if (file.exists(file.path(d, "__ReadMe.xlsx"))) d else NA_character_
})
setwd(folder)

paper_dir <- dirname(.sp)
dataset_root  <- dirname(paper_dir)
# outputs
snapshot_csv  <- file.path(paper_dir, paste0(item_name, "_snapshot.csv"))
final_csv     <- file.path(paper_dir, paste0(item_name, ".csv"))
readme_xlsx   <- file.path(dataset_root, "__ReadMe.xlsx")
public_tsv_dir<- file.path(dataset_root, "__Public", "comparative-data")
# --- YOU SET THIS MANUALLY ---
pdf_file <- file.path(paper_dir, "Herculano-Houze-2015-Decreasing sleep requirem.pdf")
## 1. SOURCE -----------------------------------------------------------------
library(rJava)
library(tabulapdf)
library(tidyverse)
library(dplyr)
library(tidyr)
library(readxl)
library(pdftools)
# Extract Table 1 (YOU control pages)
# Tables 1 and 2 are rotated landscape, so they are on the "long" side of the PDF.
# Tried to look at ways of rotating the PDF but couldn't find any that worked.
tables1 <- extract_tables(pdf_file, pages = c(6))
## 2.0 FIX FORMATTING AND SAVE SNAPSHOT ---------------------------------------
df1 <- as.data.frame(tables1[[1]])
df2 <- df1
## 2.1 Deleting empty columns-------------------------------------------------
df2 <- df2[, colSums(!(is.na(df2))) > 0]
## 2.2 Splitting the first column into two separate columns-------------------
df2 <- df2 %>%
  separate(`22age %`,
           into = c("age", "% asleep"),
           sep = "\\s+",
           convert = TRUE)
## 2.3 Naming the columns------------------------------------------------------------
names(df2) <- c("Age", "Asleep %", "MBR (g)", "NCX (g)", "NCX", "O/N", "DCX (N mg⁻¹)", "ACX (mm²)", "D/A,(N mg⁻¹mm⁻²)")
## 2.4 Replacing char "n.a" into null values-------------------------------------------------
df2[df2 == "n.a."] <- NA
## 2.5 Removing spaces-------------------------------------------------
df2 <- df2 %>%
  mutate_all(~ gsub("\\s+", "", .))
## Save snapshot------------------------------------------------------------------------------
write.csv(df2, snapshot_csv, row.names = FALSE)
## 2.6 Converting to Numeric-------------------------------------------------------
df2 <- df2 %>%
  mutate_all(~ as.numeric(.))
result_df <- df2
## 5. SAVE (LOCAL CSV + PUBLIC TSV) ------------------------------------------
final.dataframe <- result_df
# Item encoded lookup uses item_name (script filename)
filecodes <- read_excel(file.path(dataset_root, "__ReadMe.xlsx"), sheet = "Sheet1")
item_encoded <- filecodes$`Item encoded`[match(item_name, filecodes$`Item name`)]
# Local output next to the paper
write.csv(final.dataframe, final_csv, row.names = FALSE)
# Public TSV output
dir.create(public_tsv_dir, recursive = TRUE, showWarnings = FALSE)
write.table(final.dataframe,
           file = file.path(public_tsv_dir, paste0(item_encoded, ".tsv")),
           sep = "\t", row.names = FALSE)
