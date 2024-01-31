# Load necessary libraries
library(dplyr)

# List of dataframes
dataframes <- c(
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

# Initialize metadata_flags for each dataframe with a common suffix
suffix <- "_metadata_flags"
metadata_flags <- list()

for (df in dataframes) {
  metadata_flags[[paste0(df, suffix)]] <- data.frame(
    Flag_Description = c(""),
    Flag_Condition = c("")
  )
}

# Define the changes for metadata_flags$DosSantos_etal_2020_Table1_metadata_flags
metadata_flags$DosSantos_etal_2020_Table1_metadata_flags$Flag_Condition <- c("!grepl('_I.p.mg', colnames(variable))")
metadata_flags$DosSantos_etal_2020_Table1_metadata_flags$Flag_Description <- c("Secondary data variables omitted as some data found to be typos inconsistent with primary sources. Only keep I.mg")

# There are two lists cellcounts_data_list and metadata_flags
# Look into list cellcounts_data_list and loop through every dataframe. If the cellcounts_data_list[[i]] dataframe name matches any metadata_flags[i]$Flag_Condition = !na, 
# delete all values in the dataframe that match Flag_Condition 

# for (variable in dataframes) {
#   for (condition in paste0("metadata_flags[",dataframes,"]_metadata_flags$Flag_Condition") {
#     for (column in cellcounts_data_list[[variable]]) {
# if condition = TRUE{column=NULL}
#     }
#   }
# }
#   # !grepl('_I.p.mg', colnames(cellcounts_data_list$DosSantos_etal_2020_Table1))

# Assuming cellcounts_data_list is a list of dataframes
for (variable in dataframes) {
  condition <- eval(parse(text = metadata_flags[[paste0(variable, suffix)]]$Flag_Condition))
  if (!is.na(condition) && condition) {
    cellcounts_data_list[[variable]] <- lapply(cellcounts_data_list[[variable]], function(column) {
      if (condition) {
        column <- NULL
      }
      return(column)
    })
  }
}