# 1. Data comes from Fig 3 caption and was not tabulated, so a table was created, Changizi__2001_Figure3_snapshot.csv

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

# open file and read last two columns as numeric
figdata <- read.csv("Changizi__2001_Figure3_snapshot.csv", check.names = FALSE)


# 2. Make data readable
# Add unlogged data

#make numerical
figdata[, 2:3] <- lapply(figdata[, 2:3], as.numeric)

# Unlogged values of columns 2 and 3 which are log-transformed
figdata[, 4] <- 10^figdata[, 2]  # Add a new column with unlogged values of column 2
figdata[, 5] <- 10^figdata[, 3]  # Add a new column with unlogged values of column 3

# Rename columns 4 and 5 to match the headings of columns 2 and 3 without "log"
colnames(figdata)[4:5] <- sub("log ", "", colnames(figdata)[2:3])

# Remove all digits after the decimal point in columns 4 and 5 #these are not maningful since they were produced by logging
figdata[, 4:5] <- lapply(figdata[, 4:5], function(x) trunc(x))

# Set the scipen option to a high value to turn off scientific notation
options(scipen = 999)

## 3. Save

# Finalize dataframe (UPDATE!!!)
final.dataframe <- figdata

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


