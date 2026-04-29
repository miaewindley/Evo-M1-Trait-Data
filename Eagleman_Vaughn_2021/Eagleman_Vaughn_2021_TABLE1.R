## 0. PATHS (NO setwd) -------------------------------------------------------
library(rstudioapi)

script_path   <- rstudioapi::getActiveDocumentContext()$path
paper_dir     <- dirname(script_path)
table_name    <- tools::file_path_sans_ext(basename(script_path))

final_csv <- file.path(paper_dir, paste0(table_name, ".csv"))

## --- YOU SET THIS MANUALLY ---
pdf_file <- file.path(
  paper_dir,
  "Eagleman-2021-The Defensive Activation Theory_.pdf"
)

## 1. PACKAGES ---------------------------------------------------------------
library(rJava)
library(tabulapdf)
library(tidyverse)
library(stringr)

## 2. EXTRACT TABLE 1 --------------------------------------------------------
tables1 <- extract_tables(
  pdf_file,
  pages = 3,
  guess = FALSE
)

df <- as.data.frame(tables1[[1]])

## 3. REMOVE PDF ARTIFACT COLUMNS --------------------------------------------
df <- df[, !grepl("^\\.\\.\\.", colnames(df)), drop = FALSE]

## 4. CHECK & RENAME COLUMNS SAFELY ------------------------------------------

n_cols <- ncol(df)

# Expected column meaning in order (Table 1)
expected_names <- c(
  "Species",
  "Time_to_locomotion_days",
  "Time_to_weaning_days",
  "Time_to_adolescence_months",
  "REM_sleep_percent",
  "Phylogenetic_distance_Mya"
)

# Assign only as many names as columns that exist
colnames(df) <- expected_names[seq_len(n_cols)]

## 5. REMOVE NON-TABLE TEXt --------------------------------------------------
df <- df %>%
  filter(
    !is.na(Species),
    str_detect(Species, "^[A-Za-z]"),
    !str_detect(
      Species,
      "METHODS|Supplementary|sleep time|Table|Material"
    )
  )


## 6. CLEAN NUMERIC VALUES ---------------------------------------------------

final.dataframe <- df %>%
  mutate(
    Time_to_locomotion_days =
      if ("Time_to_locomotion_days" %in% names(.))
        as.numeric(str_replace(Time_to_locomotion_days, "–", NA_character_))
    else NA_real_,
    
    Time_to_weaning_days =
      if ("Time_to_weaning_days" %in% names(.))
        as.numeric(str_replace(Time_to_weaning_days, "–", NA_character_))
    else NA_real_,
    
    Time_to_adolescence_months =
      if ("Time_to_adolescence_months" %in% names(.))
        as.numeric(str_replace(Time_to_adolescence_months, "–", NA_character_))
    else NA_real_,
    
    REM_sleep_percent =
      if ("REM_sleep_percent" %in% names(.))
        as.numeric(str_remove(REM_sleep_percent, "%"))
    else NA_real_,
    
    Phylogenetic_distance_Mya =
      if ("Phylogenetic_distance_Mya" %in% names(.))
        as.numeric(Phylogenetic_distance_Mya)
    else NA_real_
  )

## 7. SAVE FINAL CSV ---------------------------------------------------------
write.csv(final.dataframe, final_csv, row.names = FALSE)
