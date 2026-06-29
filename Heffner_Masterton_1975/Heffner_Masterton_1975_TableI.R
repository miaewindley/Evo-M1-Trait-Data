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

# Manually entered data (with some copying and pasting of particular parts)
# 
# Checked (and manually corrected)  using Claude Sonnet 4.6. 
# Prompt:
# 1. Get any tables from this PDF. Recreate in new tables as spreadsheets saved in Excel
# 2. compare to the spreadsheet i made manually and tried to keep to original format. Heffner_Masterton_1975_TableI_snapshot


## 1. Read from xl
library(readxl)
tabledirectxl <- read_excel("Heffner_Masterton_1975_TableI_snapshot.xlsx")

## 2. Make column headings readable

# Rename columns 1-16
colnames(tabledirectxl)[1:17] <- c(
  "Animal",
  "Species",
  "Digital dexterity",
  "Body weight kg",
  "Number of fibers per tract",
  "Number of fibers per tract ref",
  "Largest fiber diameter µm",
  "Largest fiber diameter µm ref",
  "Average fiber size x 10ˆ5 K",
  "Area of tract mmˆ2",
  "Area of tract mmˆ2 ref",
  "Penetration down spinal cord",
  "Penetration down spinal cord ref",
  "Lamina of axon terminals deepest",
  "Lamina of axon terminals deepest ref",
  "Lamina of axon terminals densest",
  "Lamina of axon terminals densest ref"
)

## 3. Compile data into row per species and remove empty rows 

# Remove rows where the "Animal" value starts with "Table I", "Animal", or numbers in the range of 160-179. 
tabledirectxl <- tabledirectxl[!(grepl("^Table I|^Animal|^16[0-9]|^17[0-9]", tabledirectxl$Animal)), ]

# Use single square bracket subsetting with the apply function to remove rows that contain the specific text "deepest" in the column "Lamina of axon terminals deepest".
tabledirectxl <- tabledirectxl[apply(tabledirectxl, 1, function(row) !("deepest" %in% row["Lamina of axon terminals deepest"])), ]

# Split rows into two dataframes then merge them
# Make two dataframes from one
oddrows <- tabledirectxl[seq(1, nrow(tabledirectxl), by = 2), ]
evenrows <- tabledirectxl[seq(2, nrow(tabledirectxl), by = 2), ]

# Create merged_df with data from oddrows
merged_df <- oddrows

# Convert columns to numerical values
merged_df$`Digital dexterity` <- as.numeric(merged_df$`Digital dexterity`)
merged_df$`Body weight kg` <- as.numeric(merged_df$`Body weight kg`)
merged_df$`Number of fibers per tract` <- as.numeric(merged_df$`Number of fibers per tract`)
merged_df$`Largest fiber diameter µm` <- as.numeric(merged_df$`Largest fiber diameter µm`)
merged_df$`Average fiber size x 10ˆ5 K` <- as.numeric(merged_df$`Average fiber size x 10ˆ5 K`)
merged_df$`Area of tract mmˆ2` <- as.numeric(merged_df$`Area of tract mmˆ2`)
merged_df$`Area of tract mmˆ2 ref` <- as.numeric(merged_df$`Area of tract mmˆ2 ref`)
merged_df$`Lamina of axon terminals deepest` <- as.numeric(merged_df$`Lamina of axon terminals deepest`)
merged_df$`Lamina of axon terminals densest` <- as.numeric(merged_df$`Lamina of axon terminals densest`)

# Replace columns in merged_df with the corresponding column from evenrows
merged_df[["Species"]] <- evenrows[["Species"]]
merged_df[["Number of fibers per tract ref"]] <- evenrows[["Number of fibers per tract ref"]]
merged_df[["Largest fiber diameter µm ref"]] <- evenrows[["Largest fiber diameter µm ref"]]
merged_df[["Penetration down spinal cord ref"]] <- evenrows[["Penetration down spinal cord ref"]]
merged_df[["Lamina of axon terminals deepest ref"]] <- evenrows[["Lamina of axon terminals deepest ref"]]
merged_df[["Lamina of axon terminals densest ref"]] <- evenrows[["Lamina of axon terminals densest ref"]]

# Delete rows where the header column is empty or NA
merged_df <- merged_df[!is.na(merged_df$Animal), ]

# Set the scipen option to a high value to turn off scientific notation
options(scipen = 999)

## 4. Save

# Finalize dataframe (UPDATE!!!)
final.dataframe <- merged_df

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
