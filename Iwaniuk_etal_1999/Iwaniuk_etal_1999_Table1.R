## Load Libraries

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

library(readxl)
library(tidyr)
library(rstudioapi)

## 1. Source
#setwd("setwd("C:/Users/MILONI/OneDrive - University of Bath/Research Schemes/Allen Institute/Evo-M1-Trait-Data")
setwd(paste0(base, "/"))
#setwd(paste0(base, "/"))

## 2. Table 2
#1. Read direct from xl
folder_path <- paste0(folder, "/")
tabledirectxl <-
  read_excel(paste0(folder_path, "Iwaniuk_etal_1999_Table1_snapshot.xlsx"))

#2. Change header name of column 1 and 2
colnames(tabledirectxl)[1] <- "Species Generic Name"
colnames(tabledirectxl)[2] <- "Species Scientific Name"

#3. Split 2 columns containing both value and reference in [] into 4 different columns.

# Define the columns to split and their corresponding new column names
cols_to_split <- c("Depth", "Length")
new_col_names <- c("Depth", "Depth_Ref", "Length", "Length_Ref")

# Loop through the columns and split each one
for (i in seq_along(cols_to_split)) {
  tabledirectxl <- separate(
    tabledirectxl,
    col = cols_to_split[i],  # Specify the column to split
    into = c(new_col_names[i * 2 - 1], paste0(new_col_names[i * 2 - 1], "_Ref")),  # New column names with "_" before Ref
    sep = " \\[|\\]",  # Specify the separator as a regular expression to split on ' [' and ']'
    extra = "drop"  # Drop any extra pieces
  )
}

#4.  Move "Species scientific name" column and rename it
tabledirectxl <- tabledirectxl[, c("Species Scientific Name", setdiff(names(tabledirectxl), "Species Scientific Name"))]
names(tabledirectxl)[1] <- "Species"

## 3. Save
# Finalize dataframe (UPDATE!!!)
final.dataframe <- tabledirectxl

# Get Item name: Get Path of the current script, Extract the file name, Remove the ".R" extension
item_name <-
  gsub("\\.R$",
       "",
       basename(.sp))

# Get Item encoded
filecodes <- read_excel(file.path(base, "__ReadMe.xlsx"), sheet = "Sheet1")
item_encoded <-
  filecodes$"Item encoded"[match(item_name, filecodes$"Item name")]

# Save dataframe to a CSV file
write.csv(
  final.dataframe,
  file = paste0(folder_path, item_name, ".csv"),
  row.names = FALSE
)

# Save dataframe to a TSV file in the online database
tsv_file_path <- paste0(file.path(base, "__Public", "comparative-data"), "/")
write.table(
  final.dataframe,
  file = paste0(tsv_file_path, item_encoded, ".tsv"),
  sep = "\t",
  row.names = FALSE
)