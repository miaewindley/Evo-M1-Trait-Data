setwd("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/__Public/comparative-data")

# Get data
library(tidyverse)
library(readxl)

## TROUBLESHOOTING TESTS
# List all files in the directory ending with .tsv
tsv_directory_list <- list.files("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/__Public/comparative-data", pattern = "\\.tsv$", full.names = FALSE)
# Remove the .tsv extension
tsv_directory_list <- tools::file_path_sans_ext(tsv_directory_list)
tsv_directory_list

# Read tsv files using read.delim() method
tsvtesting<-read.delim("10.1126%2Fscience.aaa9101_TableS1.tsv", sep = "\t", header = TRUE, stringsAsFactors = FALSE, check.names = FALSE)


# Create a subset of filecodes based on the matching positions
match_positions <- match(filecodes$"Item encoded", item_encoded_names)
subset_data <- filecodes[!is.na(match_positions), ]
new_dataframe <- subset_data[, c("Item encoded", "Item name")]


# Create a subset of filecodes based on the matching positions
match_positions1 <- match(filecodes$"Item name", item_name)
subset_data1 <- filecodes[!is.na(match_positions1), ]
new_dataframe1 <- subset_data1[, c("Item encoded", "Item name")]

# Print the matched data
print(matched_data)

## TROUBLESHOOTINGTESTSEND

# Get all filenames from directory 
tsv_directory_list <- list.files("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/__Public/comparative-data")

# Filter files to include only those that end with ".tsv" 
tsv_names <- tsv_directory_list[grep("\\.tsv$", tsv_directory_list)]

# Maybe - Eliminate problematic ones
# tsv_names <- tsv_names[tsv_names != "10.1016%2Fj.jhevol.2008.08.004_Table2.tsv"]

# Get Item Code by removing end with ".tsv"
item_encoded_names <-  sub("\\.tsv$", "", tsv_names)

# Read Excel file with item name and item encoded TSVs
filecodes <- read_excel("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/__ReadMe.xlsx", sheet = "Sheet1")

# List of item names
item_name <- filecodes$"Item name"[match(item_encoded_names,filecodes$"Item encoded")]

# Initialize an empty list to store tsvs as data frames
tsv_data_list <- list()

# Loop through item names, read tables from TSVs, and store as data frames in the list, row.names = NULL
for (i in seq_along(item_name)) {
  cat("Processing item:", item_name[i], "\n")  # Print item name
  
  item_encoded <- filecodes$"Item encoded"[match(item_name[i], filecodes$"Item name")]
  
  # Construct the file path
  file_path <- paste0("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/__Public/comparative-data/", item_encoded, ".tsv")
  
  # Read the first few lines to check if it starts with "table"
  first_lines <- readLines(file_path, n = 5)
  starts_with_table <- any(startsWith(tolower(first_lines), "table"))
  
  # Apply different rules based on whether the file starts with "table"
  if (starts_with_table) {
    item_data <- read.delim(file = file_path, sep = "\t", header = TRUE, stringsAsFactors = FALSE, check.names = FALSE, row.names = NULL, skip = 1)
  } else {
    item_data <- read.delim(file = file_path, sep = "\t", header = TRUE, stringsAsFactors = FALSE, check.names = FALSE, row.names = NULL)
  }
  
  # Store the data frame in the list with the corresponding item name
  tsv_data_list[[item_name[i]]] <- item_data
}

list2env(tsv_data_list, envir = environment()) # Make the dataframes available in the environment

# ######OLDVERSIONHIDE
# # Loop through item names, read tables from TSVs, and store as dataframes in the list, row.names = NULL
# for (i in seq_along(item_name)) {
#   cat("Processing item:", item_name[i], "\n")  # Print item name
# 
#   
#   item_encoded <- filecodes$"Item encoded"[match(item_name[i], filecodes$"Item name")]
#   item_data <- read.table(file = paste0("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/__Public/comparative-data/", item_encoded, ".tsv"), sep = "\t", 
#                           header = TRUE, stringsAsFactors = FALSE, check.names = FALSE, row.names = NULL)
#   
#   # Store the data frame in the list with the corresponding item name
#   tsv_data_list[[item_name[i]]] <- item_data
# }
######OLDVERSIONHIDE
