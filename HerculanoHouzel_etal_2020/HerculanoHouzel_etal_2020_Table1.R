## 0. PATHS (NO setwd) -------------------------------------------------------
library(rstudioapi)

script_path   <- rstudioapi::getActiveDocumentContext()$path
paper_dir     <- dirname(script_path)
dataset_root  <- dirname(paper_dir)
table_name    <- tools::file_path_sans_ext(basename(script_path))

snapshot_csv  <- file.path(paper_dir, paste0(table_name, "_snapshot.csv"))
final_csv     <- file.path(paper_dir, paste0(table_name, ".csv"))
readme_xlsx   <- file.path(dataset_root, "__ReadMe.xlsx")
public_tsv_dir<- file.path(dataset_root, "__Public", "comparative-data")

# --- YOU SET THIS MANUALLY ---
pdf_file <- file.path(paper_dir, "Herculano-Houze-2020-Microchiropterans have a.pdf")

## 1. PACKAGES ---------------------------------------------------------------
# Migrated from the retired 'tabulizer' package to 'tabulapdf' (its maintained
# successor). Both wrap the same tabula-java engine.
library(rJava)
library(tabulapdf)
library(tidyverse)
library(readxl)

## 2. EXTRACT TABLE 1 --------------------------------------------------------
# Table 1 is on page 3. Point tabula at the data rows (caption + header
# excluded) with fixed column separators, so no whole-page text is pulled in.
# Coordinates are PDF points (1/72") from the page's top-left.
#   area    = c(top, left, bottom, right)
#   columns = x of the 7 separators between the 8 columns
tables1 <- extract_tables(
  pdf_file,
  pages   = 3,
  guess   = FALSE,
  area    = list(c(470, 50, 700, 545)),
  columns = list(c(145, 200, 273, 344, 398, 445, 493)),
  output  = "matrix"
)

df0 <- as.data.frame(tables1[[1]], stringsAsFactors = FALSE)
colnames(df0) <- c(
  "Species", "Micro/mega", "Family", "Clade", "n",
  "MBODY, g", "MBRAIN, g", "NBRAIN"
)

## 3. FOLD WRAPPED 'n' VALUES + SAVE SNAPSHOT --------------------------------
# A few 'n' cells wrap onto a second line (e.g. "2 females" / "(1H each)").
# tabula returns the wrap as an extra row that is blank except for n; fold each
# such row's n into the most recent real row. (Replaces the old hard-coded,
# species-by-species merge.)
is_blank <- function(x) is.na(x) | trimws(x) == ""

keep <- integer(0)
for (i in seq_len(nrow(df0))) {
  if (length(keep) > 0 && is_blank(df0$Species[i])) {
    last <- keep[length(keep)]
    df0$n[last] <- trimws(paste(df0$n[last], df0$n[i]))
  } else {
    keep <- c(keep, i)
  }
}
df_snapshot <- df0[keep, , drop = FALSE]
row.names(df_snapshot) <- NULL

write.csv(df_snapshot, snapshot_csv, row.names = FALSE)

## 4. MAKE DATA READABLE -----------------------------------------------------
result_df <- df_snapshot %>%
  # split "n" into count + sample notes at the first space
  separate(n, into = c("n", "SampleInfo"), sep = " ", extra = "merge", fill = "right") %>%
  mutate(
    `MBODY, g` = as.numeric(`MBODY, g`),
    `MBRAIN, g` = as.numeric(`MBRAIN, g`),
    NBRAIN = as.numeric(gsub(",", "", NBRAIN)),
    # correct species-name typo (see paper text)
    Species = if_else(Species == "Hypsignathus mostrosus",
                      "Hypsignathus monstrosus", Species)
  )

options(scipen = 999)

## 5. SAVE (LOCAL CSV + PUBLIC TSV) ------------------------------------------
final.dataframe <- result_df

filecodes    <- read_excel(readme_xlsx, sheet = "Sheet1")
item_encoded <- filecodes$`Item encoded`[match(table_name, filecodes$`Item name`)]
if (is.na(item_encoded)) stop("No 'Item encoded' in __ReadMe.xlsx for: ", table_name)

write.csv(final.dataframe, final_csv, row.names = FALSE)

dir.create(public_tsv_dir, recursive = TRUE, showWarnings = FALSE)
write.table(
  final.dataframe,
  file = file.path(public_tsv_dir, paste0(item_encoded, ".tsv")),
  sep = "\t", row.names = FALSE
)
