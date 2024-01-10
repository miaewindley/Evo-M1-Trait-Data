# Set Working Directory. Store with the spreadsheet.
setwd("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/__merging/")

# Working with cell counts data (
# 1. Create a regression of whole brain cell count on body size for all species 
# 1a. Create for Kverkova WholeBrain data from WholeBrainOlfactoryBulb by subtracting OlfactoryBulb for all variables including Neuron number and Mass cell count data in all files
# 1b. Create vectors for WholeBrain from all dfs with reference to term list: see if it can search all dfs in a folder? 
# 1c. Compile and view. Then, check which species are there.


# 1. Get data

library(dplyr)
library(readxl)

# 1.1 Create a list with all the dataframes for cell count analyses, using the tsv files in online comparative-data, and load the dataframes

# List of item names
item_name <- c(
  "DosSantos_etal_2017_TableS1",
  "DosSantos_etal_2020_Table1",
  "HerculanoHouzel_etal_2015_Table1",
  "HerculanoHouzel_etal_2015_Table2",
  "HerculanoHouzel_etal_2015_Table3",
  "HerculanoHouzel_etal_2015_Table4",
  "HerculanoHouzel_etal_2015_Table5",
  "HerculanoHouzel_etal_2020_TABLE1",
  "HerculanoHouzel_etal_2020_TABLE2",
  "JardimMesseder_etal_2017_Table1",
  "Kverkova_etal_2018_TableS1",
  "Kverkova_etal_2018_TableS5"
)

# Initialize an empty list to store data frames with cell counts data
cellcounts_data_list <- list()

# Read Excel file with item name and item encoded TSVs
filecodes <- read_excel("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/__ReadMe.xlsx", sheet = "Sheet1")

# Loop through item names, read tables from TSVs, and store as dataframes in the list
for (i in seq_along(item_name)) {
  item_encoded <- filecodes$"Item encoded"[match(item_name[i], filecodes$"Item name")]
  item_data <- read.table(file = paste0("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/__Public/comparative-data/", item_encoded, ".tsv"), 
                          header = TRUE, stringsAsFactors = FALSE, check.names = FALSE)

  # Store the data frame in the list with the corresponding item name
  cellcounts_data_list[[item_name[i]]] <- item_data
}

# # Make the dataframes available in the environment
# list2env(cellcounts_data_list, envir = environment())

## 1.2 Change to standardized term for all variables in those dfs

# Read standardized terms
standardized_term_cellcounts <- read.csv("standardized_term_cellcounts.csv", check.names=FALSE)

# Loop through each data frame to apply standardized terms
for (i in seq_along(item_name)) {
  df <- cellcounts_data_list[[item_name[i]]]
  indices <- match(colnames(df), standardized_term_cellcounts$Original_Term[standardized_term_cellcounts$Reference == item_name[i]])
  colnames(df) <- (standardized_term_cellcounts$Standardized_Term[standardized_term_cellcounts$Reference == item_name[i]])[indices]
  cellcounts_data_list[[item_name[i]]] <- df


## 1.3 Inspect and calculate variables across datasets

# 1.3.1 Get an alphabetized list of variables from all datasets in alphabetical order to examine. Q. Can any be converted?
# Initialize an empty vector to store all column names
all_variables <- character(0)
# Loop through each data frame
for (i in seq_along(item_name)) {
  # Get the data frame associated with the current name
  df <- cellcounts_data_list[[item_name[i]]]
  # Extract column names (variables) from the current data frame
  variables_in_df <- colnames(df)
  # Combine unique column names with the existing vector
  all_variables <- unique(c(all_variables, variables_in_df))
}
# Sort the column names alphabetically and view
all_variables <- sort(all_variables)
all_variables

# 1.3.2 Calculate variables to make comparisons
# Different terms were used to show that in Kverkova et al 2018 included olfactory bulb in Whole brain, but in the other datasets it did not (see definitions).
# (For rows with "Reference" starting with "Kverkova_etal_2018")  "WholeBrainOlfactoryBulb" denotes the whole brain with the olfactory bulb
# To standardize create new variables starting with "WholeBrain" before the first underscore by subtracting the "OlfactoryBulb" component from "WholeBrainOlfactoryBulb" and naming the new variable as "WholeBrain_X."
# The formula is "WholeBrain_X"="WholeBrainOlfactoryBulb_X"−"OlfactoryBulb_X"

# Loop: Calculate differences between "WholeBrainOlfactoryBulb_" and "OlfactoryBulb_" columns
for (i in seq_along(item_name)) {
  # Get the data frame associated with the current name
  df <- cellcounts_data_list[[i]]
  
  # Check if there are columns starting with "WholeBrainOlfactoryBulb_"
  wholebrainolfactorybulb <- grep("^WholeBrainOlfactoryBulb_", colnames(df), value = TRUE)
  
  # Loop through matching columns and calculate differences
  for (matching in wholebrainolfactorybulb) {
    # Extract the common suffix
    suffix <- sub("^WholeBrainOlfactoryBulb_", "", matching)
    
    # Check if corresponding "OlfactoryBulb_" column exists
    olfactorybulb_check <- paste0("OlfactoryBulb_", suffix)
    
    if (olfactorybulb_check %in% colnames(df)) {
      # Calculate the differences and store in the corresponding "WholeBrain_" columns
      new_col_wholebrain <- paste0("WholeBrain_", suffix)
      df[[new_col_wholebrain]] <- df[[matching]] - df[[olfactorybulb_check]]
    }
  }
  
  # Update the data frame in the list
  cellcounts_data_list[[i]] <- df
}

## 1.4 Get a full list of species in alphabetical order to examine
# Initialize an empty vector to store species names
all_species <- character(0)

# Loop through each data frame in the list
for (i in seq_along(cellcounts_data_list)) {
  # Combine the unique species names with the existing vector in alphabetical order
  all_species <- sort(unique(c(all_species, cellcounts_data_list[[i]]$Species)))
}
# View
all_species

## 2 Get a full list of WholeBrain_N.n from all dataframes in the list cellcounts_data_list.

WholeBrain_N.n <- character(0)

# Loop through each data frame in the list
for (i in seq_along(cellcounts_data_list)) {
  # Extract the "Species" column from the current data frame
  species_col <- cellcounts_data_list[[i]]$Species
  
  # Combine the unique species names with the existing vector
  all_species <- unique(c(all_species, species_col))
}

# Sort the vector in alphabetical order
all_species <- sort(all_species)
all_species

# 2. Compile total of all datasets on Whole Brain cellular composition
# 2Qa. What data should be included/excluded when doing an imputation?
# 2Qb. Should data be converted if there is an equation for exact conversion? e.g. WholeBrain ; BodyMasskg

    