## 1. SOURCE -------------------------------------------------------------------

library(rvest)
library(dplyr)
library(tidyverse)
library(readxl)

script_path   <- rstudioapi::getActiveDocumentContext()$path
paper_dir     <- dirname(script_path)
dataset_root  <- dirname(paper_dir)
table_name    <- tools::file_path_sans_ext(basename(script_path))


# outputs

snapshot_csv  <- file.path(paper_dir, paste0(table_name, "_snapshot.csv"))
final_csv     <- file.path(paper_dir, paste0(table_name, ".csv"))
readme_xlsx   <- file.path(dataset_root, "__ReadMe.xlsx")
public_tsv_dir<- file.path(dataset_root, "__Public", "comparative-data")


## 2.00 Reading from website ---------------------------------------------------

url <- "https://pmc.ncbi.nlm.nih.gov/articles/PMC4614783/"

page <- read_html(url)

## 2.01 Saving table1 ----------------------------------------------------------

tables <- page %>% html_elements("table") %>% html_table(fill = TRUE)

df1 <- tables[[1]]

df2 <- df1

## 2.02 Fixing titles ----------------------------------------------------------

colnames(df2) <- c("species", "brain mass (g or cm3)", "daily sleep (h)", "D/A (N mg−1 mm−2)", "NCX", "DNCX (N mg−1)","ACX (mm2)", "O/N", "T", "MCX (g or cm3)")

## 2.03 Removing square brackets  ----------------------------------------------

df2[] <- lapply(df2, function(x) gsub("\\[.*?\\]", "", x))

df3 <- df2

## 2.04 Saving snapshot --------------------------------------------------------

write.csv(df2, snapshot_csv, row.names = FALSE)

## 2.05 convert "n.a" to Null values -------------------------------------------

df3[] <- lapply(df3, function(x) ifelse(x == "n.a.", NA, x))

## 2.06 Removing asterisks  ----------------------------------------------------

df3[] <- lapply(df3, function(x) gsub("\\*", "", x))

## 2.07 Removing random letters  -----------------------------------------------

df3[ , -1] <- lapply(df3[ , -1], function(x) gsub("([0-9])([A-Za-z])$", "\\1", x))

## 2.08 Removing spaces  -------------------------------------------------------

df3[ , -1] <- lapply(df3[ , -1], function(x) gsub(" ", "", x))

## 2.09 Removing repeated mammalian titles  ------------------------------------

df3[ , -1] <- lapply(df3[ , -1], function(x) gsub("[A-Za-z]", "", x))

## 2.10 Fixing index form ------------------------------------------------------

convert_index_form <- function(x) {
  x <- gsub("×10\\^", "e", x)   
  x <- gsub("×10", "e", x)      
}

df3[[5]] <- convert_index_form(df3[[5]])

## 2.11 Making first column characters -----------------------------------------

df3[[1]] <- as.character(df3[[1]])

## 2.12 Converting to Numeric---------------------------------------------------

df3[ , -1] <- lapply(df3[ , -1], as.numeric)

## 2.13 Making Clade column-----------------------------------------------------

categories <- c("Primates", "Eulipotyphla", "Glires", "Afrotheria", "Artiodactyla", "Scandentia")

df3 <- df3 |>
  mutate(category = if_else(species %in% categories, species, NA_character_)) |>
  fill(category, .direction = "down") |>
  filter(!species %in% categories) |>
  relocate(category, .after = species)



## 2.17 Saving Final table------------------------------------------------------

result_df <- df3

# Item encoded look up uses table_name (script file name)
filecodes <- read_excel(file.path(dataset_root, "__ReadMe.xlsx"), sheet = "Sheet1")
item_encoded <- filecodes$`Item encoded`[match(table_name, filecodes$`Item name`)]

# Local output next to the paper
write.csv(result_df, final_csv, row.names = FALSE)

# Public TSV output
# dir.create(public_tsv_dir, recursive = TRUE, showWarnings = FALSE)
# write.table(final.dataframe,
#            file = file.path(public_tsv_dir, paste0(item_encoded, ".tsv")),
#            sep = "\t", row.names = FALSE)





