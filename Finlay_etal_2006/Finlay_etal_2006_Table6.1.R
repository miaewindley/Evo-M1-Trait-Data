## 1. Read direct from xl

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
item_name <- table_name <- tools::file_path_sans_ext(basename(.sp))  # = file name (matches __ReadMe.xlsx)
base <- dataset_root <- local({                                      # repo root; NA if run as a lone folder
  d <- folder
  while (dirname(d) != d && !file.exists(file.path(d, "__ReadMe.xlsx"))) d <- dirname(d)
  if (file.exists(file.path(d, "__ReadMe.xlsx"))) d else NA_character_
})
setwd(folder)

setwd(folder)

library(readxl)
tablefromxl <- read_excel("Finlay_etal_2006_Table6.1_snapshot.xlsx", col_types = c("text", "text", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric"))

# 2. Species 
# Create a new data frame with "Species" as the first column copied from Species Name #double square brackets to prevent converting spaces
tablefromxl$Species <- tablefromxl[["Species Name"]]

# rename row names with typos 
tablefromxl$Species <- gsub("Felis cattus", "Felis catus", tablefromxl$Species)
tablefromxl$Species <- gsub("Echinops telfairi", "Echinops telfari", tablefromxl$Species)


# # rename row names based on text, refs, also see Kaskan et al 2005, Changizi 2001
# tablefromxl$Species <- gsub("Mouse sp.", "Mus sp.", tablefromxl$Species)
# # Changizi 2011 cites Krubitzer 1995 which only mentions Sciurus carolinensis
# tablefromxl$Species <- gsub("Squirrel sp.", "Squirrel check species", tablefromxl$Species)


# Set the scipen option to a high value to turn off scientific notation
options(scipen = 999)

## 4. Save

# Finalize dataframe (UPDATE!!!)
final.dataframe <- tablefromxl 

# Get Item name: Get Path of the current script, Extract the file name, Remove the ".R" extension
library(rstudioapi)
item_name <- gsub("\\.R$", "", basename(.sp))

# Get Item encoded
library(readxl) 
filecodes <- read_excel(file.path(base, "__ReadMe.xlsx"), sheet = "Sheet1")
item_encoded <- filecodes$"Item encoded"[match(item_name, filecodes$"Item name")]

# Save dataframe to a CSV file
write.csv(final.dataframe, file = paste0(item_name, ".csv"), row.names = FALSE)

# Save dataframe to a TSV file in the online database
tsv_file_path <- paste0(file.path(base, "__Public", "comparative-data"), "/")
write.table(final.dataframe, file = paste0(tsv_file_path, item_encoded, ".tsv"), sep = "\t", row.names = FALSE)




