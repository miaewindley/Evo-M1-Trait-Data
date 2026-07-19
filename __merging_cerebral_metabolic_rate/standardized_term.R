library(tidyverse)

# Set working directory
setwd("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/__merging_cerebral_metabolic_rate")

# Define the folder containing the per-reference term files
folder_path <- "standardized_term_by_reference"

# Get list of CSV files in the folder
csv_files <- list.files(path = folder_path, pattern = "\\.csv$", full.names = TRUE)

# Read and stack all files, keeping all columns
combined_df <- csv_files |>
  map(~ readr::read_csv(.x, show_col_types = FALSE)) |>
  list_rbind()

# Write output
readr::write_csv(combined_df, "standardized_term_cerebral_metabolic_rate.csv")

# For checking: line up equivalent terms across references
pivot_df <- combined_df %>%
  select(Original_Term, Reference, Standardized_Term) %>%
  distinct() %>%
  pivot_wider(names_from = Reference, values_from = Standardized_Term)
