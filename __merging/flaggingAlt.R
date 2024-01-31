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
metadata_flags <- list()

for (df in dataframes) {
  metadata_flags[[df]] <- data.frame(
    Flag_Description = c(NA),
    Flag_Condition = c(NA)
  )
}

# Define the changes for metadata_flags$DosSantos_etal_2020_Table1_metadata_flags
metadata_flags$DosSantos_etal_2020_Table1$Flag_Condition <- c("!grepl('_I.p.mg', colnames(cellcounts_data_list[[df_name]]))")
metadata_flags$DosSantos_etal_2020_Table1$Flag_Description <- c("Secondary data variables omitted as some data found to be typos inconsistent with primary sources. Only keep I.mg")

# There are two lists, cellcounts_data_list and metadata_flags
# Look into list cellcounts_data_list and loop through every dataframe. 
# Find the cellcounts_data_list dataframe name that matches the metadata_flags dataframe name.
# If the Flag_Condition value is NA, skip 
# If the Flag_Condition value is a string, use the string (without quotes) as an R script designating a set of datapoints in that dataframe, and delete all values in the dataframe thatare in that  set of datapoints

# Loop through every dataframe in cellcounts_data_list
for (df_name in names(cellcounts_data_list)) {
  
  # Find the corresponding metadata_flags element
  flag_df <- metadata_flags[[df_name]]
  
  # Check if Flag_Condition is NA
  if (is.na(flag_df$Flag_Condition)) {
    next  # Skip to the next iteration
  }
  
  # If Flag_Condition is a string, use it as an R script
  if (is.character(flag_df$Flag_Condition)) {
    
    # Assuming your R script is a valid condition
    condition_script <- flag_df$Flag_Condition
    
    # Designate a set of datapoints in the dataframe and delete them
    subset_condition <- eval(parse(text = condition_script))
    
    # Check the type and structure of subset_condition
    print(class(subset_condition))
    print(str(subset_condition))
    
    # Filter the dataframe using subset
    cellcounts_data_list[[df_name]] <- subset(cellcounts_data_list[[df_name]], !subset_condition)
  }
}

# View the modified list of dataframes outside the loop
View(cellcounts_data_list)


# If Flag_Condition is a string, use it as an R script
if (is.character(flag_df$Flag_Condition)) {
  
  # Assuming your R script is a valid condition
  condition_script <- flag_df$Flag_Condition
  
  # Designate a set of datapoints in the dataframe and delete them
  subset_condition <- eval(parse(text = condition_script))
  
  # Check the type and structure of subset_condition
  print(class(subset_condition))
  print(str(subset_condition))
  
  # Check if subset_condition is not NULL before filtering
  if (!is.null(subset_condition)) {
    # Filter the dataframe using subset
    cellcounts_data_list[[df_name]] <- subset(cellcounts_data_list[[df_name]], !subset_condition)
  } else {
    print("Subset condition is NULL. Skipping filtering.")
  }
}
