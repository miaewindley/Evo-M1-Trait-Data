## 0. PATHS --------------------------------------------------------
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
folder <- paper_dir <- dirname(.sp)
item_name <- table_name <- tools::file_path_sans_ext(basename(.sp))
base <- dataset_root <- local({
  d <- folder
  while (dirname(d) != d && !file.exists(file.path(d, "__ReadMe.xlsx"))) d <- dirname(d)
  if (file.exists(file.path(d, "__ReadMe.xlsx"))) d else NA_character_
})
setwd(folder)
snapshot_csv   <- file.path(paper_dir, paste0(table_name, "_snapshot.csv"))
final_csv      <- file.path(paper_dir, paste0(table_name, ".csv"))
resolution_csv <- file.path(paper_dir, "species_resolution_Lyamin_Table1.csv")
public_tsv_dir <- if (!is.na(dataset_root)) file.path(dataset_root, "__Public", "comparative-data") else NA
readme_xlsx    <- if (!is.na(dataset_root)) file.path(dataset_root, "__ReadMe.xlsx") else NA

## 1. PACKAGES ------------------------------------------------------
library(tidyverse)
library(stringr)
library(readxl)

## 2. LOAD SNAPSHOT -------------------------------------------------
# Lyamin et al. (2008) Table 1, "Number of muscle jerks in cetaceans".
# Printed columns: Cetacean species | Age | Number of jerks | Reference
df_snapshot <- read.csv(snapshot_csv, stringsAsFactors = FALSE,
                        check.names = FALSE, encoding = "UTF-8")
resolution  <- read.csv(resolution_csv, stringsAsFactors = FALSE,
                        check.names = FALSE, encoding = "UTF-8")

## 3. STANDARDISE --> FINAL TABLE ----------------------------------
# number_of_jerks is kept verbatim. The printed values use incompatible
# denominators -- totals over a period, per-day rates, means with SD, upper
# bounds, per-individual splits, and one qualitative entry -- so the column is
# not a comparable quantity and is not coerced to numeric here.
final.dataframe <- df_snapshot %>%
  rename(
    common_name_printed = `Cetacean species`,
    age_printed         = Age,
    number_of_jerks     = `Number of jerks`,
    reference           = Reference
  ) %>%
  mutate(
    common_name_printed = str_squish(common_name_printed),
    common_name         = tolower(common_name_printed),
    age_printed         = str_squish(age_printed),
    number_of_jerks     = str_squish(number_of_jerks),
    reference           = str_squish(reference),
    n_animals = case_when(
      str_detect(age_printed, regex("^one\\b",   ignore_case = TRUE)) ~ 1L,
      str_detect(age_printed, regex("^two\\b",   ignore_case = TRUE)) ~ 2L,
      str_detect(age_printed, regex("^three\\b", ignore_case = TRUE)) ~ 3L,
      str_detect(age_printed, regex("three .* and one", ignore_case = TRUE)) ~ 4L,
      TRUE ~ NA_integer_
    ),
    age_class = case_when(
      str_detect(age_printed, regex("calf",   ignore_case = TRUE)) ~ "calf",
      str_detect(age_printed, regex("adult",  ignore_case = TRUE)) ~ "adult",
      str_detect(age_printed, regex("year",   ignore_case = TRUE)) ~ "juvenile",
      TRUE ~ NA_character_
    ),
    reference_unpublished = str_detect(reference, regex("unpublished", ignore_case = TRUE)),
    reference_in_press    = str_detect(reference, regex("in press",    ignore_case = TRUE))
  ) %>%
  left_join(resolution %>% select(Common_name_printed, Species, species_confidence),
            by = c("common_name_printed" = "Common_name_printed")) %>%
  rename(species = Species) %>%
  select(species, species_confidence, common_name, common_name_printed,
         n_animals, age_class, age_printed,
         number_of_jerks, reference, reference_unpublished, reference_in_press)

## 3b. CHECKS ------------------------------------------------------
# The bottlenose row is "Three adult males and one adult female" = 4 animals;
# the ^three rule would otherwise catch it first. Verify the override held.
unresolved <- final.dataframe %>% filter(is.na(species))
if (nrow(unresolved)) warning("No binomial for: ",
                              paste(unique(unresolved$common_name_printed), collapse = ", "))

if (nrow(final.dataframe) != 7) warning("Expected 7 printed rows, got ", nrow(final.dataframe))

## 4. SAVE OUTPUTS -------------------------------------------------
options(scipen = 999)
write.csv(final.dataframe, final_csv, row.names = FALSE)

if (!is.na(dataset_root) && file.exists(readme_xlsx)) {
  filecodes    <- read_excel(readme_xlsx, sheet = "Sheet1")
  item_encoded <- filecodes$`Item encoded`[match(table_name, filecodes$`Item name`)]
  if (is.na(item_encoded)) {
    warning("No 'Item encoded' found in __ReadMe.xlsx for Item name: ", table_name,
            " -- add a row to __ReadMe.xlsx before final submission.")
  } else {
    dir.create(public_tsv_dir, recursive = TRUE, showWarnings = FALSE)
    write.table(final.dataframe,
                file = file.path(public_tsv_dir, paste0(item_encoded, ".tsv")),
                sep = "\t", row.names = FALSE)
  }
}
