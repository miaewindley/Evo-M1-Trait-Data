## 0. PATHS (NO setwd) -------------------------------------------------------
paper_dir <- here::here("Garwicz_etal_2009")
dataset_root  <- dirname(paper_dir)
table_name    <- "Garwicz_etal_2009_TableS1"
snapshot_s1   <- file.path(paper_dir, "Garwicz_etal_2009_TableS1_snapshot.csv")
snapshot_s2   <- file.path(paper_dir, "Garwicz_etal_2009_TableS2_snapshot.csv")
final_csv     <- file.path(paper_dir, paste0(table_name, ".csv"))
readme_xlsx   <- file.path(dataset_root, "__ReadMe.xlsx")
public_tsv_dir<- file.path(dataset_root, "__Public", "comparative-data")
pdf_file <- file.path(paper_dir, "0905777106si.pdf")
## 1. PACKAGES ---------------------------------------------------------------
# Uses 'tabulapdf' (maintained successor to 'tabulizer'). The old, orphaned
# 'tabulizerjars' dependency has been removed -- tabulapdf does not need it.
library(rJava)
library(tabulapdf)
library(dplyr)
library(tidyr)
library(stringr)
library(readxl)
## 2. EXTRACT BOTH TABLES + SAVE SNAPSHOTS -----------------------------------
# Table S1 (taxonomy) is on page 5, Table S2 (database) on page 6. Target each
# table's data rows with fixed column separators and assign headers directly
# (so the old "first row as header" / PC-PN rename patches are no longer
# needed). Coordinates are PDF points (1/72") from the top-left.
# --- Table S1: page 5, 4 columns ---
s1 <- extract_tables(
  pdf_file, pages = 5, guess = FALSE,
  area = list(c(69, 30, 320, 545)),
  columns = list(c(140, 290, 425)),
  output = "matrix"
)
df2 <- as.data.frame(s1[[1]], stringsAsFactors = FALSE)
colnames(df2) <- c("Lay term", "Order/suborder", "Family", "Genus/species")
# --- Table S2: page 6, 9 columns ("WO, days" splits into PN and PC) ---
s2 <- extract_tables(
  pdf_file, pages = 6, guess = FALSE,
  area = list(c(84, 30, 335, 575)),
  columns = list(c(125, 188, 255, 322, 380, 431, 468, 515)),
  output = "matrix"
)
df1 <- as.data.frame(s2[[1]], stringsAsFactors = FALSE)
colnames(df1) <- c(
  "Species (lay term)", "AbsBrM, g", "NeoBrM (1), g", "BoM, g", "Gest., days",
  "WO, days_PN", "WO, days_PC", "Pre/Alt", "HSP"
)
write.csv(df1, snapshot_s2, row.names = FALSE)
write.csv(df2, snapshot_s1, row.names = FALSE)
## 3. MAKE DATA READABLE -----------------------------------------------------
# Merge taxonomy (S1) onto the database (S2) by the common (lay) name.
colnames(df2)[colnames(df2) == "Lay term"] <- "Common name"
colnames(df1)[colnames(df1) == "Species (lay term)"] <- "Common name"
tog <- merge(df1, df2[, c("Common name", "Genus/species")], by = "Common name", all.x = TRUE)
# Spell out abbreviations; use the binomial (Genus/species) as Species.
tog <- tog %>%
  rename(
    `Absolute Brain Mass (g)`             = `AbsBrM, g`,
    `Neonatal Brain Mass (g)`             = `NeoBrM (1), g`,
    `Body Mass (g)`                       = `BoM, g`,
    `Gestation (days)`                    = `Gest., days`,
    `Walking onset (Postnatal days)`      = `WO, days_PN`,
    `Walking onset (Postconception days)` = `WO, days_PC`,
    `Precocial/Altricial`                 = `Pre/Alt`,
    `Hindlimb Standing Position`          = `HSP`,
    Species                               = `Genus/species`
  ) %>%
  select(Species, everything())
# Split the literature reference "(n)" out of the value columns into "<col> Ref".
separate_ref <- function(df, col) {
  df %>%
    mutate(
      !!sym(paste0(col, " Ref")) := str_extract(!!sym(col), "\\(([^)]+)\\)"),
      !!sym(col)                 := str_remove(!!sym(col), " \\([^)]*\\)")
    )
}
tog <- tog %>%
  separate_ref("Absolute Brain Mass (g)") %>%
  separate_ref("Body Mass (g)") %>%
  separate_ref("Gestation (days)") %>%
  separate_ref("Walking onset (Postnatal days)")
# "—" means no value for neonatal brain mass.
tog$`Neonatal Brain Mass (g)` <- ifelse(tog$`Neonatal Brain Mass (g)` == "—", NA, tog$`Neonatal Brain Mass (g)`)
# Remove commas and coerce the six measure columns (positions 3:8) to numeric.
for (col in 3:8) tog[[col]] <- gsub(",", "", tog[[col]])
tog[, 3:8] <- lapply(tog[, 3:8], as.numeric)
options(scipen = 999)
## 4. SAVE (LOCAL CSV + PUBLIC TSV) ------------------------------------------
final.dataframe <- tog
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
